import SwiftUI

struct ContentView: View {
  @AppStorage(AppStorageKeys.selectedLayerIndex) private var storedLayerIndex = 0
  @AppStorage(AppStorageKeys.selectedPhaseIndex) private var storedPhaseIndex = 0
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
    self.init(dependencies: .live())
  }

  /// Designated initializer; takes a pre-built dependency bundle so the
  /// `live()` graph is testable and substitutable. See
  /// `ContentViewDependencies` for the construction logic.
  init(dependencies: ContentViewDependencies) {
    self.journalRepository = dependencies.journalRepository
    self.catalogRepository = dependencies.catalogRepository
    self.journalClient = dependencies.journalClient
    _viewModel = StateObject(wrappedValue: dependencies.viewModel)
    _flowCoordinator = StateObject(wrappedValue: dependencies.flowCoordinator)
    _syncSettingsViewModel = StateObject(wrappedValue: dependencies.syncSettingsViewModel)
    _networkMonitor = StateObject(wrappedValue: dependencies.networkMonitor)
    _journalQueue = StateObject(wrappedValue: dependencies.journalQueue)
    _syncService = StateObject(wrappedValue: dependencies.syncService)
    _layerSelection = State(initialValue: dependencies.initialLayer)
    _phaseSelection = State(initialValue: dependencies.initialPhaseSelection)
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

  /// Adds lifecycle hooks and routes navigation-state synchronization
  /// through `NavigationSyncModifier`.
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
      .navigationSync(
        viewModel: viewModel,
        layerSelection: $layerSelection,
        phaseSelection: $phaseSelection,
        storedLayerIndex: $storedLayerIndex,
        storedPhaseIndex: $storedPhaseIndex
      )
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
}

#Preview {
  ContentView()
}
