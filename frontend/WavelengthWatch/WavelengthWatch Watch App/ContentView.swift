import SwiftUI

/// Thin shell that names the app's root view. All composition lives
/// in `RootShellView`; ObservableObject dependencies are read from the
/// environment (injected at the App layer in `WavelengthWatchApp`).
struct ContentView: View {
  let journalClient: JournalClientProtocol
  let journalRepository: JournalRepositoryProtocol
  let catalogRepository: CatalogRepositoryProtocol

  var body: some View {
    RootShellView(
      journalClient: journalClient,
      journalRepository: journalRepository,
      catalogRepository: catalogRepository
    )
  }
}

#Preview {
  let deps = ContentViewDependencies.live()
  return ContentView(
    journalClient: deps.journalClient,
    journalRepository: deps.journalRepository,
    catalogRepository: deps.catalogRepository
  )
  .environmentObject(deps.viewModel)
  .environmentObject(deps.flowCoordinator)
  .environmentObject(deps.syncSettingsViewModel)
  .environmentObject(deps.networkMonitor)
  .environmentObject(deps.journalQueue)
  .environmentObject(deps.syncService)
  .environmentObject(deps.navigationViewModel)
  .environmentObject(NotificationDelegate())
}
