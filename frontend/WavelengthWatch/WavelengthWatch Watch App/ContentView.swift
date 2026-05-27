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

  private var flowSubmissionPresenter: FlowSubmissionPresenter {
    FlowSubmissionPresenter(flowCoordinator: flowCoordinator, viewModel: viewModel)
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

  /// Adds lifecycle hooks via `MainContentLifecycleModifier`.
  /// Navigation-state reconciliation lives in `navigationViewModel`.
  private var contentWithEvents: some View {
    MainContentStates(viewModel: viewModel, navigationViewModel: navigationViewModel)
      .mainContentLifecycle(
        viewModel: viewModel,
        syncService: syncService,
        journalQueue: journalQueue
      )
  }

  /// Adds the alert presentations, sheet stack, and onboarding-check task.
  private var contentWithDialogs: some View {
    contentWithEvents
      .journalFlowAlerts(
        viewModel: viewModel,
        flowCoordinator: flowCoordinator,
        flowSubmissionPresenter: flowSubmissionPresenter
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
