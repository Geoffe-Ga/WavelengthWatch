import SwiftUI

/// Bundles the main shell's lifecycle hooks:
///
/// - `.ignoresSafeArea(edges: .bottom)` for the watch's home-indicator
///   inset so content extends to the screen edge.
/// - `.task { viewModel.loadCatalog() }` for the initial catalog fetch.
/// - `.task { syncService.startAutoSync() }` for the connectivity-driven
///   auto-sync subscription.
/// - `.onChange(of: syncService.syncStatus)` to forward sync transitions
///   into the view model's queued-pending feedback computation.
///
/// Extracting these as a single modifier keeps ContentView focused on
/// composition and lets the lifecycle wiring be unit-tested or reused
/// (e.g. in previews) without re-implementing the four-call chain.
struct MainContentLifecycleModifier: ViewModifier {
  @ObservedObject var viewModel: ContentViewModel
  @ObservedObject var syncService: JournalSyncService
  @ObservedObject var journalQueue: JournalQueue

  func body(content: Content) -> some View {
    content
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
}

// MARK: - View Extension

extension View {
  /// Applies the main shell's lifecycle hooks (catalog load, auto-sync
  /// kickoff, sync-status change forwarding, bottom safe-area
  /// extension).
  func mainContentLifecycle(
    viewModel: ContentViewModel,
    syncService: JournalSyncService,
    journalQueue: JournalQueue
  ) -> some View {
    modifier(
      MainContentLifecycleModifier(
        viewModel: viewModel,
        syncService: syncService,
        journalQueue: journalQueue
      )
    )
  }
}
