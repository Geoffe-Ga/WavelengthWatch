import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

struct CatalogRepositoryFallbackTests {
  private struct NetworkDown: Error {}

  private func makeCatalog(phase: String = "Rising") -> CatalogResponseModel {
    CatalogResponseModel(
      phaseOrder: [phase],
      layers: [
        CatalogLayerModel(
          id: 1,
          color: "Beige",
          title: "BEIGE",
          subtitle: "Survival",
          phases: [
            CatalogPhaseModel(
              id: 1,
              name: phase,
              medicinal: [CatalogCurriculumEntryModel(id: 10, dosage: .medicinal, expression: "Grounded")],
              toxic: [],
              strategies: []
            ),
          ]
        ),
      ]
    )
  }

  private func makeRepository(
    remote: CatalogRemoteServicing,
    cache: CatalogCachePersisting,
    now: Date,
    ttl: TimeInterval = 60 * 60 * 24
  ) -> CatalogRepository {
    CatalogRepository(
      remote: remote,
      cache: cache,
      dateProvider: { now },
      cacheTTL: ttl
    )
  }

  @Test("loadCatalog returns stale cached catalog when remote fetch fails")
  func loadCatalog_remoteFails_returnsStaleCache() async throws {
    let originalCatalog = makeCatalog(phase: "Rising")
    let cache = InMemoryCatalogCacheMock()
    let initialDate = Date(timeIntervalSince1970: 1_700_000_000)

    let working = makeRepository(
      remote: CatalogRemoteStub(response: originalCatalog),
      cache: cache,
      now: initialDate
    )
    _ = try await working.loadCatalog(forceRefresh: false)

    let staleDate = initialDate.addingTimeInterval(60 * 60 * 25)
    let failing = makeRepository(
      remote: FailingRemoteStub(error: NetworkDown()),
      cache: cache,
      now: staleDate
    )

    let result = try await failing.loadCatalog(forceRefresh: false)
    #expect(result == originalCatalog)
  }

  @Test("loadCatalog with forceRefresh propagates remote errors even if a cache exists")
  func loadCatalog_forceRefresh_throwsOnRemoteFailureEvenWithCache() async throws {
    let originalCatalog = makeCatalog(phase: "Peaking")
    let cache = InMemoryCatalogCacheMock()
    let now = Date(timeIntervalSince1970: 1_700_000_000)

    let working = makeRepository(
      remote: CatalogRemoteStub(response: originalCatalog),
      cache: cache,
      now: now
    )
    _ = try await working.loadCatalog(forceRefresh: false)

    let failing = makeRepository(
      remote: FailingRemoteStub(error: NetworkDown()),
      cache: cache,
      now: now
    )
    await #expect(throws: Error.self) {
      _ = try await failing.loadCatalog(forceRefresh: true)
    }
  }

  @Test("loadCatalog still throws when remote fails and there is no cache at all")
  func loadCatalog_remoteFailsWithEmptyCache_throws() async throws {
    let cache = InMemoryCatalogCacheMock()
    let repository = makeRepository(
      remote: FailingRemoteStub(error: NetworkDown()),
      cache: cache,
      now: Date(timeIntervalSince1970: 1_700_000_000)
    )

    await #expect(throws: Error.self) {
      _ = try await repository.loadCatalog(forceRefresh: false)
    }
  }

  @Test("loadCatalog with forceRefresh throws when remote fails and there is no cache")
  func loadCatalog_forceRefreshWithEmptyCache_throws() async throws {
    let cache = InMemoryCatalogCacheMock()
    let repository = makeRepository(
      remote: FailingRemoteStub(error: NetworkDown()),
      cache: cache,
      now: Date(timeIntervalSince1970: 1_700_000_000)
    )

    await #expect(throws: Error.self) {
      _ = try await repository.loadCatalog(forceRefresh: true)
    }
  }
}
