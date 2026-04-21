import SwiftUI

struct ContentView: View {
  @AppStorage("selectedLayerIndex") private var storedLayerIndex = 0
  @AppStorage("selectedPhaseIndex") private var storedPhaseIndex = 0
  @StateObject private var viewModel: ContentViewModel
  @StateObject private var flowCoordinator: FlowCoordinator
  @StateObject private var syncSettingsViewModel: SyncSettingsViewModel
  @StateObject private var networkMonitor: NetworkMonitor
  @StateObject private var journalQueue: JournalQueue
  @StateObject private var syncService: JournalSyncService
  @EnvironmentObject private var notificationDelegate: NotificationDelegate
  let journalClient: JournalClientProtocol
  let journalRepository: JournalRepositoryProtocol
  let catalogRepository: CatalogRepositoryProtocol
  @State private var layerSelection: Int
  @State private var phaseSelection: Int
  @State private var showLayerIndicator = false
  @State private var hideIndicatorTask: Task<Void, Never>?
  @State private var showingMenu = false
  @State private var showingOnboarding = false
  @State private var isShowingDetailView = false
  @State private var navigationPath = NavigationPath()

  init() {
    let configuration = AppConfiguration()
    let apiClient = APIClient(baseURL: configuration.apiBaseURL)
    let repository = CatalogRepository(
      remote: CatalogAPIService(apiClient: apiClient),
      cache: FileCatalogCacheStore()
    )
    let persistentRepo = JournalRepository()
    let journalRepository: JournalRepositoryProtocol
    do {
      try persistentRepo.open()
      journalRepository = persistentRepo
    } catch {
      // Fallback to in-memory storage when SQLite fails (e.g., in SwiftUI previews,
      // during testing, or if database is corrupted). This keeps the app functional
      // but data won't persist. Analytics will show empty until journal entries are
      // logged in this session.
      print("⚠️ Failed to open journal database: \(error). Falling back to in-memory storage.")
      journalRepository = InMemoryJournalRepository()
    }
    self.journalRepository = journalRepository
    self.catalogRepository = repository
    let syncSettings = SyncSettings()
    let journalQueue: JournalQueue
    do {
      journalQueue = try JournalQueue()
    } catch {
      // The documents directory is unavailable in SwiftUI previews and on a
      // few read-only storage configurations. Fall back to a temp-dir queue
      // so the UI can still render even though entries won't persist across
      // launches.
      print("⚠️ Failed to initialize journal queue: \(error). Falling back to temp storage.")
      let fallbackPath = NSTemporaryDirectory() + "journal_queue_fallback.sqlite"
      // swiftlint:disable:next force_try  -- temp dir is always writable.
      journalQueue = try! JournalQueue(databasePath: fallbackPath)
    }
    _journalQueue = StateObject(wrappedValue: journalQueue)
    let monitor = NetworkMonitor()
    _networkMonitor = StateObject(wrappedValue: monitor)
    let journalClient = JournalClient(
      apiClient: apiClient,
      repository: journalRepository,
      syncSettings: syncSettings,
      queue: journalQueue
    )
    self.journalClient = journalClient
    let sync = JournalSyncService(
      queue: journalQueue,
      apiClient: apiClient,
      networkMonitor: monitor
    )
    _syncService = StateObject(wrappedValue: sync)
    let initialLayer = UserDefaults.standard.integer(forKey: "selectedLayerIndex")
    let initialPhase = UserDefaults.standard.integer(forKey: "selectedPhaseIndex")
    let model = ContentViewModel(
      catalogRepository: repository,
      journalRepository: journalRepository,
      journalClient: journalClient,
      initialLayerIndex: initialLayer,
      initialPhaseIndex: initialPhase
    )
    _viewModel = StateObject(wrappedValue: model)
    _syncSettingsViewModel = StateObject(wrappedValue: SyncSettingsViewModel(syncSettings: syncSettings))
    let coordinator = FlowCoordinator(contentViewModel: model)
    _flowCoordinator = StateObject(wrappedValue: coordinator)
    _layerSelection = State(initialValue: initialLayer)
    _phaseSelection = State(initialValue: initialPhase + 1)
  }

  /// Clamped layer selection that's always valid for the current filteredLayers
  ///
  /// This fixes #183: scroll position and digital crown bindings must return valid indices
  /// even when layerSelection is stale (e.g., after filter mode change).
  ///
  /// **Timing note:** `layerSelection` itself gets updated to the clamped value in
  /// `onChange(of: viewModel.layerFilterMode)`, but that handler fires AFTER the initial
  /// render. This computed property ensures bindings always return valid values even
  /// during that timing window, preventing SwiftUI from rendering with invalid state.
  private var clampedLayerSelection: Int {
    guard viewModel.filteredLayers.count > 0 else { return 0 }
    return min(layerSelection, viewModel.filteredLayers.count - 1)
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      ZStack {
        if viewModel.layers.isEmpty {
          if viewModel.isLoading {
            ProgressView("Loading curriculum…")
              .foregroundStyle(.white)
          } else if let error = viewModel.loadErrorMessage {
            VStack(spacing: 12) {
              Text(error)
                .multilineTextAlignment(.center)
              Button("Retry") {
                Task { await viewModel.retry() }
              }
            }
            .padding()
          } else {
            ProgressView("Loading curriculum…")
          }
        } else if viewModel.phaseOrder.isEmpty {
          Text("No phase information available.")
        } else {
          layeredContent
        }
      }
      .ignoresSafeArea(edges: .bottom)
      .task { await viewModel.loadCatalog() }
      .task {
        // Kick off auto-sync once when the view appears. The service
        // subscribes to NetworkMonitor and triggers a sync whenever
        // connectivity is restored.
        syncService.startAutoSync()
      }
      .onChange(of: syncService.syncStatus) { _, newValue in
        viewModel.handleSyncStatusChange(newValue, totalPending: journalQueue.pendingCount)
      }
      .onChange(of: viewModel.phaseOrder) {
        adjustPhaseSelection()
      }
      .onChange(of: layerSelection) { _, newValue in
        // Convert filtered index to layer ID
        if let layerId = viewModel.filteredIndexToLayerId(newValue) {
          viewModel.selectedLayerId = layerId
          // Convert layer ID to full array index
          if let fullIndex = viewModel.layerIdToIndex(layerId) {
            viewModel.selectedLayerIndex = fullIndex
            storedLayerIndex = fullIndex
          }
        }
        showLayerIndicator = true
        scheduleLayerIndicatorHide()
      }
      .onChange(of: viewModel.selectedLayerId) { _, newLayerId in
        // When selectedLayerId changes, update layerSelection to match in filtered array
        guard let layerId = newLayerId else { return }
        if let filteredIndex = viewModel.layerIdToFilteredIndex(layerId) {
          if layerSelection != filteredIndex {
            layerSelection = filteredIndex
          }
        }
      }
      .onChange(of: viewModel.layerFilterMode) { _, _ in
        // When filter mode changes, actively sync layerSelection to the correct filtered index
        // for the current selectedLayerId. This fixes #180: strategy cards rendering tiny after
        // flow completion because layerSelection wasn't synced to the new filtered index.
        guard let layerId = viewModel.selectedLayerId,
              let filteredIndex = viewModel.layerIdToFilteredIndex(layerId)
        else {
          // Fallback: clamp to valid range if no selected layer ID
          let maxIndex = max(0, viewModel.filteredLayers.count - 1)
          if layerSelection > maxIndex {
            layerSelection = maxIndex
          }
          return
        }

        // Actively set layerSelection to the correct filtered index for the selected layer
        if layerSelection != filteredIndex {
          layerSelection = filteredIndex
        }
      }
      .onChange(of: phaseSelection) { _, newValue in
        guard viewModel.phaseOrder.count > 0 else { return }
        let adjusted = PhaseNavigator.adjustedSelection(newValue, phaseCount: viewModel.phaseOrder.count)
        if adjusted != newValue {
          phaseSelection = adjusted
        }
        let normalized = PhaseNavigator.normalizedIndex(adjusted, phaseCount: viewModel.phaseOrder.count)
        viewModel.selectedPhaseIndex = normalized
        storedPhaseIndex = normalized
      }
      .onChange(of: viewModel.selectedPhaseIndex) { _, newValue in
        let expected = newValue + 1
        if phaseSelection != expected {
          phaseSelection = expected
        }
      }
      .alert(item: $viewModel.journalFeedback) { feedback in
        switch feedback.kind {
        case .success:
          Alert(
            title: Text("Entry Logged"),
            message: Text("Thanks for checking in."),
            dismissButton: .default(Text("OK")) { viewModel.journalFeedback = nil }
          )
        case let .queued(message):
          Alert(
            title: Text("Saved Offline"),
            message: Text(message),
            dismissButton: .default(Text("OK")) { viewModel.journalFeedback = nil }
          )
        case let .syncing(current, total):
          Alert(
            title: Text("Syncing"),
            message: Text("Syncing \(current) of \(total) entr\(total == 1 ? "y" : "ies")…"),
            dismissButton: .default(Text("OK")) { viewModel.journalFeedback = nil }
          )
        case let .syncSuccess(count):
          Alert(
            title: Text("Synced"),
            message: Text("\(count) entr\(count == 1 ? "y" : "ies") synced successfully."),
            dismissButton: .default(Text("OK")) { viewModel.journalFeedback = nil }
          )
        case let .failure(message):
          Alert(
            title: Text("Something went wrong"),
            message: Text(message),
            dismissButton: .default(Text("OK")) { viewModel.journalFeedback = nil }
          )
        }
      }
      .alert("Primary emotion selected", isPresented: .constant(flowCoordinator.currentStep == .confirmingPrimary)) {
        Button("Add Secondary Emotion") {
          flowCoordinator.promptForSecondary()
        }
        Button("Add Strategy") {
          flowCoordinator.promptForStrategy()
        }
        Button("Done") {
          Task {
            do {
              try await flowCoordinator.submit()
              // Success - reset flow state (quick log doesn't use review sheet)
              flowCoordinator.reset()
            } catch JournalError.queuedForRetry {
              viewModel.journalFeedback = .init(
                kind: .queued("Saved offline. Will sync automatically.")
              )
              flowCoordinator.reset()
            } catch {
              viewModel.journalFeedback = .init(kind: .failure("Failed to log emotion: \(error.localizedDescription)"))
            }
          }
        }
        Button("Cancel", role: .cancel) {
          flowCoordinator.cancel()
        }
      } message: {
        if let primary = flowCoordinator.selections.primary {
          Text("You selected \"\(primary.expression)\". What would you like to do next?")
        }
      }
      .alert("Secondary emotion selected", isPresented: .constant(flowCoordinator.currentStep == .confirmingSecondary)) {
        Button("Add Strategy") {
          flowCoordinator.promptForStrategy()
        }
        Button("Done") {
          Task {
            do {
              try await flowCoordinator.submit()
              // Success - reset flow state (quick log doesn't use review sheet)
              flowCoordinator.reset()
            } catch JournalError.queuedForRetry {
              viewModel.journalFeedback = .init(
                kind: .queued("Saved offline. Will sync automatically.")
              )
              flowCoordinator.reset()
            } catch {
              viewModel.journalFeedback = .init(kind: .failure("Failed to log emotions: \(error.localizedDescription)"))
            }
          }
        }
        Button("Cancel", role: .cancel) {
          flowCoordinator.cancel()
        }
      } message: {
        if let secondary = flowCoordinator.selections.secondary {
          Text("You selected \"\(secondary.expression)\". What would you like to do next?")
        } else {
          Text("What would you like to do next?")
        }
      }
      .alert("Strategy selected", isPresented: .constant(flowCoordinator.currentStep == .confirmingStrategy)) {
        Button("Continue to Review") {
          flowCoordinator.showReview()
        }
        Button("Cancel", role: .cancel) {
          flowCoordinator.cancel()
        }
      } message: {
        if let strategy = flowCoordinator.selections.strategy {
          Text("You selected \"\(strategy.strategy)\". Continue to review?")
        } else {
          Text("Continue to review?")
        }
      }
      .onChange(of: notificationDelegate.scheduledNotificationReceived) { _, newValue in
        if let notification = newValue {
          viewModel.setInitiatedBy(notification.initiatedBy)
          notificationDelegate.clearNotificationState()
        }
      }
      .onChange(of: flowCoordinator.currentStep) { _, newStep in
        // Pop navigation to root when flow state transitions
        // This fixes #157, #162, #164: prevents user from being stuck in detail views
        switch newStep {
        case .selectingPrimary, .selectingSecondary, .selectingStrategy:
          // When transitioning to selection steps, pop to root so user can navigate freely
          if !navigationPath.isEmpty {
            navigationPath.removeLast(navigationPath.count)
          }
        case .idle:
          // When flow completes or is canceled, pop to root
          if !navigationPath.isEmpty {
            navigationPath.removeLast(navigationPath.count)
          }
        default:
          break
        }
      }
      .sheet(isPresented: $showingMenu) {
        NavigationStack {
          MenuView(
            journalClient: journalClient,
            syncSettingsViewModel: syncSettingsViewModel,
            journalQueue: journalQueue,
            syncService: syncService,
            networkMonitor: networkMonitor,
            isPresented: $showingMenu
          )
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Done") {
                showingMenu = false
              }
            }
          }
        }
      }
      .sheet(isPresented: $showingOnboarding) {
        OnboardingView(
          viewModel: syncSettingsViewModel,
          isPresented: $showingOnboarding
        )
        .interactiveDismissDisabled()
      }
      .sheet(isPresented: .constant(flowCoordinator.currentStep == .review)) {
        FlowReviewSheet(flowCoordinator: flowCoordinator)
      }
      .task {
        // Check onboarding completion once when view appears
        if !syncSettingsViewModel.hasCompletedOnboarding {
          showingOnboarding = true
        }
      }
      .toolbar {
        if !isShowingDetailView {
          ToolbarItem(placement: .topBarLeading) {
            // Show back chevron when in flow mode, menu button otherwise
            if flowCoordinator.currentStep != .idle {
              Button {
                flowCoordinator.cancel()
              } label: {
                Image(systemName: "chevron.left")
                  .font(.system(size: UIConstants.menuButtonSize))
                  .foregroundColor(.white.opacity(0.7))
              }
              .buttonStyle(.plain)
            } else {
              Button {
                showingMenu = true
              } label: {
                Image(systemName: "ellipsis.circle")
                  .font(.system(size: UIConstants.menuButtonSize))
                  .foregroundColor(.white.opacity(0.7))
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .navigationTitle("")
      .navigationDestination(for: DetailDestination.self) { destination in
        switch destination {
        case let .curriculum(layer, phase, colorName):
          CurriculumDetailView(layer: layer, phase: phase, color: Color(stage: colorName))
        case let .strategy(phase, colorName):
          StrategyListView(phase: phase, color: Color(stage: colorName))
        }
      }
    }
    .environmentObject(viewModel)
    .environmentObject(flowCoordinator)
    .environment(\.isShowingDetailView, $isShowingDetailView)
  }

  private var layeredContent: some View {
    GeometryReader { geometry in
      ScrollViewReader { proxy in
        ScrollView(.vertical, showsIndicators: false) {
          LazyVStack(spacing: -20) {
            ForEach(viewModel.filteredLayers.indices, id: \.self) { index in
              let layer = viewModel.filteredLayers[index]
              LayerCardView(
                layer: layer,
                phaseCount: viewModel.phaseOrder.count,
                selection: $phaseSelection,
                layerIndex: index,
                selectedLayerIndex: clampedLayerSelection,
                geometry: geometry,
                screenWidth: geometry.size.width
              )
              .id(index)
            }
          }
          .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollDisabled(false)
        .scrollPosition(id: .init(
          get: { clampedLayerSelection },
          set: { newId in
            if let newId = newId as? Int, newId != layerSelection {
              layerSelection = newId
            }
          }
        ))
        .digitalCrownRotation(
          .init(
            get: { Double(clampedLayerSelection) },
            set: { newValue in
              guard viewModel.filteredLayers.count > 0 else { return }
              let clampedValue = Int(round(newValue)).clamped(to: 0 ... (viewModel.filteredLayers.count - 1))
              if clampedValue != layerSelection {
                layerSelection = clampedValue
              }
            }
          ),
          from: 0,
          through: Double(max(viewModel.filteredLayers.count - 1, 0)),
          by: 1.0,
          sensitivity: .medium,
          isContinuous: false,
          isHapticFeedbackEnabled: true
        )
        .onChange(of: layerSelection) { _, newValue in
          guard viewModel.filteredLayers.count > 0, newValue < viewModel.filteredLayers.count else { return }
          withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo(newValue, anchor: .center)
          }
        }
        .onAppear {
          guard viewModel.filteredLayers.count > 0, layerSelection < viewModel.filteredLayers.count else { return }
          proxy.scrollTo(layerSelection, anchor: .center)
          showLayerIndicator = true
          scheduleLayerIndicatorHide()
        }
        .overlay(alignment: .trailing) {
          enhancedLayerIndicator(in: geometry.size)
        }
        // Note: DragGesture uses raw layerSelection for bounds checking because we're
        // setting a new value (not reading for display). The bounds check against
        // filteredLayers.count is safe because we're modifying layerSelection, which
        // will then be clamped via clampedLayerSelection for any binding reads.
        .simultaneousGesture(
          DragGesture()
            .onEnded { value in
              let threshold: CGFloat = 30
              if value.translation.height > threshold, layerSelection > 0 {
                layerSelection -= 1
              } else if value.translation.height < -threshold, layerSelection < viewModel.filteredLayers.count - 1 {
                layerSelection += 1
              }
              showLayerIndicator = true
              scheduleLayerIndicatorHide()
            }
        )
      }
    }
  }

  private func adjustPhaseSelection() {
    guard viewModel.phaseOrder.count > 0 else { return }
    let adjusted = PhaseNavigator.adjustedSelection(phaseSelection, phaseCount: viewModel.phaseOrder.count)
    if adjusted != phaseSelection {
      phaseSelection = adjusted
    }
  }

  private func enhancedLayerIndicator(in size: CGSize) -> some View {
    VStack {
      Spacer()
      ZStack(alignment: .top) {
        // Background track
        Capsule()
          .fill(Color.white.opacity(0.1))
          .frame(width: 4, height: size.height * 0.5)

        // Current layer indicators stack
        VStack(spacing: 2) {
          ForEach(viewModel.filteredLayers.indices, id: \.self) { index in
            let layer = viewModel.filteredLayers[index]
            let isSelected = index == clampedLayerSelection
            let distance = abs(index - clampedLayerSelection)

            Capsule()
              .fill(
                isSelected ?
                  LinearGradient(
                    gradient: Gradient(colors: [
                      Color(stage: layer.color),
                      Color(stage: layer.color).opacity(0.7),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                  ) :
                  LinearGradient(
                    gradient: Gradient(colors: [
                      Color(stage: layer.color).opacity(0.3),
                      Color(stage: layer.color).opacity(0.1),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                  )
              )
              .frame(
                width: isSelected ? 8 : 4,
                height: isSelected ? 16 : 8
              )
              .overlay(
                Capsule()
                  .stroke(
                    isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.1),
                    lineWidth: 0.5
                  )
              )
              .shadow(
                color: isSelected ? Color(stage: layer.color) : Color.clear,
                radius: isSelected ? 3 : 0
              )
              .scaleEffect(distance > 2 ? 0.6 : 1.0)
              .opacity(distance > 3 ? 0 : 1)
              .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: clampedLayerSelection)
          }
        }
      }
      .offset(x: -6) // Use offset instead of padding to avoid layout impact when opacity changes
      Spacer()
    }
    .opacity(showLayerIndicator ? 1 : 0)
    .transition(.opacity)
  }

  private func scheduleLayerIndicatorHide() {
    hideIndicatorTask?.cancel()
    hideIndicatorTask = Task {
      try? await Task.sleep(nanoseconds: 1_000_000_000)
      guard !Task.isCancelled else { return }
      await MainActor.run {
        withAnimation(.easeOut(duration: 0.3)) {
          showLayerIndicator = false
        }
      }
    }
  }
}

#Preview {
  ContentView()
}
