import SwiftUI

struct ContentView: View {
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
  @StateObject private var navigationViewModel: NavigationViewModel
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
    _navigationViewModel = StateObject(wrappedValue: dependencies.navigationViewModel)
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

  /// Adds lifecycle hooks. Navigation-state reconciliation now lives in
  /// `navigationViewModel`, which observes `viewModel` directly.
  private var contentWithEvents: some View {
    MainContentStates(viewModel: viewModel, navigationViewModel: navigationViewModel)
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
      .mainContentDialogs(
        viewModel: viewModel,
        flowCoordinator: flowCoordinator,
        syncSettingsViewModel: syncSettingsViewModel,
        notificationDelegate: notificationDelegate,
        journalClient: journalClient,
        journalQueue: journalQueue,
        syncService: syncService,
        networkMonitor: networkMonitor,
        showingMenu: $showingMenu,
        showingOnboarding: $showingOnboarding,
        navigationPath: $navigationPath
      )
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
}

#Preview {
  ContentView()
}
