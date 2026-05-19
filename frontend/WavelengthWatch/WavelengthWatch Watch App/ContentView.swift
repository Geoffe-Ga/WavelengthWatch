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
    let journalQueue = Self.makeJournalQueue()
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

  /// Builds a JournalQueue with progressive fallback: documents directory →
  /// NSTemporaryDirectory → in-memory SQLite. The in-memory leg has no
  /// filesystem dependency, so it cannot fail in normal operation; if even
  /// that throws, the device is in a state where no offline persistence is
  /// possible and crashing surfaces the problem rather than silently
  /// dropping entries.
  private static func makeJournalQueue() -> JournalQueue {
    do {
      return try JournalQueue()
    } catch {
      print("⚠️ Documents-dir journal queue init failed: \(error). Trying temp dir.")
    }
    let fallbackPath = NSTemporaryDirectory() + "journal_queue_fallback.sqlite"
    do {
      return try JournalQueue(databasePath: fallbackPath)
    } catch {
      print("⚠️ Temp-dir journal queue init failed: \(error). Falling back to in-memory.")
    }
    do {
      return try JournalQueue(databasePath: ":memory:")
    } catch {
      fatalError("In-memory journal queue init failed unexpectedly: \(error)")
    }
  }

  /// Submits the current FlowCoordinator entry and renders the appropriate
  /// feedback. Centralised so the two confirmation alerts (primary and
  /// secondary) share identical queued/failure handling — the only thing
  /// that varies is the failure copy.
  @MainActor
  private func submitFlowEntry(failurePrefix: String) async {
    do {
      try await flowCoordinator.submit()
      flowCoordinator.reset()
    } catch JournalError.queuedForRetry {
      viewModel.journalFeedback = .init(
        kind: .queued("Saved offline. Will sync automatically.")
      )
      flowCoordinator.reset()
    } catch {
      viewModel.journalFeedback = .init(
        kind: .failure("\(failurePrefix): \(error.localizedDescription)")
      )
    }
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
      contentWithDialogs
        .toolbar { toolbarContent }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .wlNavigationBar()
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

  // MARK: - Body decomposition

  // The view body chains ~30 modifiers across lifecycle, onChange, alerts,
  // sheets, toolbar, and navigation. Swift 6's type checker can't resolve
  // that single expression in reasonable time, so we stage the chain
  // through intermediate `some View` properties — each return type erases
  // the upstream complexity, letting the checker rest.

  /// Inner content — the ZStack only, no modifiers.
  private var contentZStack: some View {
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
  }

  /// Adds lifecycle hooks and state-sync `onChange` handlers.
  private var contentWithEvents: some View {
    contentZStack
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
  }

  /// Adds the alert presentations, sheet stack, and onboarding-check task.
  private var contentWithDialogs: some View {
    contentWithEvents
      .alert(item: $viewModel.journalFeedback) { feedback in
        JournalFeedbackAlert.make(feedback) { viewModel.journalFeedback = nil }
      }
      .flowConfirmationAlerts(
        flowCoordinator: flowCoordinator,
        onPrimarySubmit: { await submitFlowEntry(failurePrefix: "Failed to log emotion") },
        onSecondarySubmit: { await submitFlowEntry(failurePrefix: "Failed to log emotions") }
      )
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
  }

  /// Top-bar toolbar: back chevron when in flow mode, menu button otherwise.
  private var toolbarContent: some ToolbarContent {
    MainNavigationToolbar(
      isShowingDetailView: isShowingDetailView,
      isInFlow: flowCoordinator.currentStep != .idle,
      onBack: { flowCoordinator.cancel() },
      onMenu: { showingMenu = true }
    )
  }

  private var layeredContent: some View {
    LayerScrollView(
      viewModel: viewModel,
      layerSelection: $layerSelection,
      phaseSelection: $phaseSelection
    )
  }

  private func adjustPhaseSelection() {
    guard viewModel.phaseOrder.count > 0 else { return }
    let adjusted = PhaseNavigator.adjustedSelection(phaseSelection, phaseCount: viewModel.phaseOrder.count)
    if adjusted != phaseSelection {
      phaseSelection = adjusted
    }
  }
}

#Preview {
  ContentView()
}
