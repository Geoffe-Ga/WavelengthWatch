import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

/// Tests for the CatalogRepository's stale-cache graceful-degradation behavior.
///
/// The watch is offline-first: when the cache is stale (older than the TTL)
/// and the remote fetch fails (offline / backend down), the repository must
/// return the stale cached catalog rather than throw — otherwise curriculum
/// browsing vanishes every 24 hours.
///
/// Lives next to the legacy `CatalogRepositoryTests` in
/// `WavelengthWatch_Watch_AppTests.swift`, hence the distinct struct name.
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

  /// Returns a repository that writes/reads through a shared in-memory cache
  /// at the provided clock instant.
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
    let cache = InMemoryCatalogCache()
    let initialDate = Date(timeIntervalSince1970: 1_700_000_000)

    // 1. First successful load populates the cache at `initialDate`.
    let working = makeRepository(
      remote: CatalogRemoteStub(response: originalCatalog),
      cache: cache,
      now: initialDate
    )
    _ = try await working.loadCatalog(forceRefresh: false)

    // 2. Advance the clock past the TTL — the cache is now stale, and the
    //    remote is now down.
    let staleDate = initialDate.addingTimeInterval(60 * 60 * 25)
    let failing = makeRepository(
      remote: FailingRemoteStub(error: NetworkDown()),
      cache: cache,
      now: staleDate
    )

    // 3. The repository must fall back to the stale cache, not throw.
    let result = try await failing.loadCatalog(forceRefresh: false)
    #expect(result == originalCatalog)
  }

  @Test("loadCatalog with forceRefresh propagates remote errors even if a cache exists")
  func loadCatalog_forceRefresh_throwsOnRemoteFailureEvenWithCache() async throws {
    let originalCatalog = makeCatalog(phase: "Peaking")
    let cache = InMemoryCatalogCache()
    let now = Date(timeIntervalSince1970: 1_700_000_000)

    // Populate cache.
    let working = makeRepository(
      remote: CatalogRemoteStub(response: originalCatalog),
      cache: cache,
      now: now
    )
    _ = try await working.loadCatalog(forceRefresh: false)

    // forceRefresh = true means the caller wants fresh data; on remote failure
    // we must propagate (no silent stale return).
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
    let cache = InMemoryCatalogCache()
    let repository = makeRepository(
      remote: FailingRemoteStub(error: NetworkDown()),
      cache: cache,
      now: Date(timeIntervalSince1970: 1_700_000_000)
    )

    await #expect(throws: Error.self) {
      _ = try await repository.loadCatalog(forceRefresh: false)
    }
  }
}
