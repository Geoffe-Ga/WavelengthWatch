import Foundation

/// Bundles the dependencies an analytics surface needs to link into
/// `JournalEntryListView` drill-downs. When absent, views render
/// statically without navigation wrapping so tests that only care
/// about data transformation remain simple.
struct JournalDrilldownContext {
  let journalRepository: JournalRepositoryProtocol
  let catalog: CatalogResponseModel
}
