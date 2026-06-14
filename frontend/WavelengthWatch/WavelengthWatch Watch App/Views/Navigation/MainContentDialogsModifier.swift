import SwiftUI

/// Bundles the dialog stack and lifecycle handlers attached to the
/// main shell content:
///
/// - **Notification-driven `initiatedBy`** — when a scheduled
///   notification fires while the app is foregrounded, the delegate's
///   `scheduledNotificationReceived` carries the `InitiatedBy` to
///   apply to the next entry.
/// - **Menu sheet** — wrapped in its own `NavigationStack` with a
///   "Done" cancellation button so it can present nested sheets.
/// - **Onboarding sheet** — gated by `SyncSettingsViewModel`, modal,
///   non-interactive-dismiss.
/// - **Flow review sheet** — presented while `flowCoordinator.currentStep
///   == .review`.
/// - **Onboarding-check `.task`** — runs once on appear; flips
///   `showingOnboarding = true` if the user hasn't completed
///   onboarding yet.
struct MainContentDialogsModifier: ViewModifier {
  @ObservedObject var viewModel: ContentViewModel
  @ObservedObject var flowCoordinator: FlowCoordinator
  @ObservedObject var syncSettingsViewModel: SyncSettingsViewModel
  @ObservedObject var notificationDelegate: NotificationDelegate

  let journalClient: JournalClientProtocol
  @ObservedObject var journalQueue: JournalQueue
  @ObservedObject var syncService: JournalSyncService
  @ObservedObject var networkMonitor: NetworkMonitor

  @Binding var showingMenu: Bool
  @Binding var showingOnboarding: Bool

  func body(content: Content) -> some View {
    content
      .onChange(of: notificationDelegate.scheduledNotificationReceived) { _, newValue in
        if let notification = newValue {
          viewModel.setInitiatedBy(notification.initiatedBy)
          notificationDelegate.clearNotificationState()
        }
      }
      .sheet(isPresented: $showingMenu) { menuSheet }
      .sheet(isPresented: $showingOnboarding) { onboardingSheet }
      .task {
        if !syncSettingsViewModel.hasCompletedOnboarding {
          showingOnboarding = true
        }
      }
  }

  // MARK: - Sheets

  private var menuSheet: some View {
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
          Button("Done") { showingMenu = false }
        }
      }
    }
  }

  private var onboardingSheet: some View {
    OnboardingView(
      viewModel: syncSettingsViewModel,
      isPresented: $showingOnboarding
    )
    .interactiveDismissDisabled()
  }
}

extension View {
  /// Attaches the main shell's dialog stack and lifecycle handlers.
  /// See `MainContentDialogsModifier` for the per-handler contract.
  func mainContentDialogs(
    viewModel: ContentViewModel,
    flowCoordinator: FlowCoordinator,
    syncSettingsViewModel: SyncSettingsViewModel,
    notificationDelegate: NotificationDelegate,
    journalClient: JournalClientProtocol,
    journalQueue: JournalQueue,
    syncService: JournalSyncService,
    networkMonitor: NetworkMonitor,
    showingMenu: Binding<Bool>,
    showingOnboarding: Binding<Bool>
  ) -> some View {
    modifier(MainContentDialogsModifier(
      viewModel: viewModel,
      flowCoordinator: flowCoordinator,
      syncSettingsViewModel: syncSettingsViewModel,
      notificationDelegate: notificationDelegate,
      journalClient: journalClient,
      journalQueue: journalQueue,
      syncService: syncService,
      networkMonitor: networkMonitor,
      showingMenu: showingMenu,
      showingOnboarding: showingOnboarding
    ))
  }
}
