import SwiftUI

/// Root shell that composes the main app surface: the `NavigationStack`,
/// the dual-axis content states, lifecycle hooks, alert/dialog stack,
/// toolbar, and destination routing.
///
/// All shared `ObservableObject` dependencies are pulled from the
/// environment (injected at the App layer in `WavelengthWatchApp`).
/// The three protocol-typed services (`journalClient`,
/// `journalRepository`, `catalogRepository`) come in as init parameters
/// because Swift environment values don't compose cleanly with protocol
/// existentials.
///
/// Extracted from `ContentView` so the view that names the app's root
/// can stay a thin shell — this view owns the sheet/navigation state
/// and the modifier-chain staging required by Swift 6's type-checker.
struct RootShellView: View {
  @EnvironmentObject private var viewModel: ContentViewModel
  @EnvironmentObject private var flowCoordinator: FlowCoordinator
  @EnvironmentObject private var syncSettingsViewModel: SyncSettingsViewModel
  @EnvironmentObject private var networkMonitor: NetworkMonitor
  @EnvironmentObject private var journalQueue: JournalQueue
  @EnvironmentObject private var syncService: JournalSyncService
  @EnvironmentObject private var navigationViewModel: NavigationViewModel
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
