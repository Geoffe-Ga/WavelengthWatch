import SwiftUI

struct ContentView: View {
  @ObservedObject var viewModel: ContentViewModel
  @ObservedObject var flowCoordinator: FlowCoordinator
  @ObservedObject var syncSettingsViewModel: SyncSettingsViewModel
  @ObservedObject var networkMonitor: NetworkMonitor
  @ObservedObject var journalQueue: JournalQueue
  @ObservedObject var syncService: JournalSyncService
  @ObservedObject var navigationViewModel: NavigationViewModel
  @EnvironmentObject private var notificationDelegate: NotificationDelegate
  let journalClient: JournalClientProtocol
  let journalRepository: JournalRepositoryProtocol
  let catalogRepository: CatalogRepositoryProtocol
  @State private var showingMenu = false
  @State private var showingOnboarding = false
  @State private var isShowingDetailView = false
  @State private var navigationPath = NavigationPath()

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
          DetailDestinationView(destination: destination)
        }
    }
    .environmentObject(viewModel)
    .environmentObject(flowCoordinator)
    .environment(\.isShowingDetailView, $isShowingDetailView)
  }

  // MARK: - Body decomposition

  //
  // The view body chains ~30 modifiers across lifecycle, onChange, alerts,
  // sheets, toolbar, and navigation. Swift 6's type checker can't resolve
  // that single expression in reasonable time, so we stage the chain
  // through intermediate `some View` properties — each return type erases
  // the upstream complexity, letting the checker rest.

  private var contentWithEvents: some View {
    MainContentStates(viewModel: viewModel, navigationViewModel: navigationViewModel)
      .mainContentLifecycle(
        viewModel: viewModel,
        syncService: syncService,
        journalQueue: journalQueue
      )
  }

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
  let deps = ContentViewDependencies.live()
  return ContentView(
    viewModel: deps.viewModel,
    flowCoordinator: deps.flowCoordinator,
    syncSettingsViewModel: deps.syncSettingsViewModel,
    networkMonitor: deps.networkMonitor,
    journalQueue: deps.journalQueue,
    syncService: deps.syncService,
    navigationViewModel: deps.navigationViewModel,
    journalClient: deps.journalClient,
    journalRepository: deps.journalRepository,
    catalogRepository: deps.catalogRepository
  )
  .environmentObject(NotificationDelegate())
}
