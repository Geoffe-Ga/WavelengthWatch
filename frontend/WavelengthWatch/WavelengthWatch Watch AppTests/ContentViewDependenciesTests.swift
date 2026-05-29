import Testing
@testable import WavelengthWatch_Watch_App

/// Coverage for `ContentViewDependencies`' progressive fallback factories (#333).
@MainActor
struct ContentViewDependenciesTests {
  private struct FactoryFailure: Error {}

  // MARK: - makeJournalRepository

  @Test("makeJournalRepository returns the persistent repo when the open succeeds")
  func makeJournalRepository_returnsPersistentOnSuccess() {
    let persistent = InMemoryJournalRepository()
    let result = ContentViewDependencies.makeJournalRepository(openPersistent: { persistent })
    #expect(result.repository as AnyObject === persistent)
    #expect(result.isInMemoryFallback == false)
  }

  @Test("makeJournalRepository falls back to in-memory and signals isInMemoryFallback when the open fails")
  func makeJournalRepository_fallsBackOnOpenFailure() {
    let result = ContentViewDependencies.makeJournalRepository(openPersistent: {
      throw FactoryFailure()
    })
    #expect(result.repository is InMemoryJournalRepository)
    #expect(result.isInMemoryFallback == true)
  }

  // MARK: - makeJournalQueue

  @Test("makeJournalQueue uses the documents queue when it opens")
  func makeJournalQueue_usesDocumentsWhenAvailable() throws {
    let documents = try JournalQueue(databasePath: ":memory:")
    let queue = ContentViewDependencies.makeJournalQueue(
      documentsQueue: { documents },
      tempQueue: { throw FactoryFailure() },
      inMemoryQueue: { throw FactoryFailure() }
    )
    #expect(queue === documents)
  }

  @Test("makeJournalQueue falls through to the temp queue when documents fails")
  func makeJournalQueue_fallsThroughToTemp() throws {
    let temp = try JournalQueue(databasePath: ":memory:")
    let queue = ContentViewDependencies.makeJournalQueue(
      documentsQueue: { throw FactoryFailure() },
      tempQueue: { temp },
      inMemoryQueue: { throw FactoryFailure() }
    )
    #expect(queue === temp)
  }

  @Test("makeJournalQueue falls through to in-memory when documents and temp fail")
  func makeJournalQueue_fallsThroughToInMemory() throws {
    let inMemory = try JournalQueue(databasePath: ":memory:")
    let queue = ContentViewDependencies.makeJournalQueue(
      documentsQueue: { throw FactoryFailure() },
      tempQueue: { throw FactoryFailure() },
      inMemoryQueue: { inMemory }
    )
    #expect(queue === inMemory)
  }

  // MARK: - live()

  @Test("live composes the dependency graph with shared instances wired through")
  func live_composesGraph() {
    let deps = ContentViewDependencies.live()
    // The flow coordinator must be built against the same view-model the
    // bundle hands to ContentView — a real wiring invariant, not just
    // "live() didn't crash".
    #expect(deps.flowCoordinator.contentViewModel === deps.viewModel)
  }

  @Test("live wires a single shared syncSettings instance through the graph")
  func live_exposesSharedSyncSettings() {
    let deps = ContentViewDependencies.live()
    #expect(deps.syncSettings === deps.syncSettingsViewModel.syncSettings)
  }
}
