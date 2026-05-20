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
    let repo = ContentViewDependencies.makeJournalRepository(openPersistent: { persistent })
    #expect(repo as AnyObject === persistent)
  }

  @Test("makeJournalRepository falls back to in-memory when the open fails")
  func makeJournalRepository_fallsBackOnOpenFailure() {
    let repo = ContentViewDependencies.makeJournalRepository(openPersistent: {
      throw FactoryFailure()
    })
    #expect(repo is InMemoryJournalRepository)
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

  @Test("live composes the full dependency graph without crashing")
  func live_composesGraph() {
    let deps = ContentViewDependencies.live()
    // initialPhaseSelection carries the +1 infinite-scroll offset, so it is
    // always >= 1; reaching this assertion proves every field was built.
    #expect(deps.initialPhaseSelection >= 1)
  }
}
