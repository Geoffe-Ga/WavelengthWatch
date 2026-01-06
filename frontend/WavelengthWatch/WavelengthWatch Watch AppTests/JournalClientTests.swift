import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

/// Comprehensive tests for JournalClient local-first behavior and sync scenarios.
@Suite("JournalClient Local-First Tests")
struct JournalClientLocalFirstTests {
  // MARK: - Local Save Tests

  @Test func localSaveSucceedsEvenWhenSyncFails() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = FailingAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submit(
      curriculumID: 42,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated
    )

    // Entry should be saved locally despite sync failure
    #expect(entry.curriculumID == 42)
    #expect(entry.syncStatus == SyncStatus.failed)
    #expect(try repository.count() == 1)
    #expect(try repository.fetch(id: entry.id) != nil)
  }

  @Test func localSaveFailsIfRepositoryThrows() async throws {
    let repository = FailingJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    let apiClient = SuccessfulAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    await #expect(throws: JournalDatabaseError.self) {
      try await client.submit(
        curriculumID: 42,
        secondaryCurriculumID: nil,
        strategyID: nil,
        initiatedBy: .self_initiated
      )
    }
  }

  // MARK: - Sync Status Transition Tests

  @Test func syncStatusStartsAsPending() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = false
    let apiClient = SuccessfulAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submit(
      curriculumID: 42,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated
    )

    #expect(entry.syncStatus == SyncStatus.pending)
    #expect(entry.serverId == nil)
  }

  @Test func syncStatusTransitionsToPendingToSynced() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = SuccessfulAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submit(
      curriculumID: 42,
      secondaryCurriculumID: 10,
      strategyID: 5,
      initiatedBy: .self_initiated
    )

    #expect(entry.syncStatus == SyncStatus.synced)
    #expect(entry.serverId == 999)
    #expect(try repository.fetch(id: entry.id)?.syncStatus == SyncStatus.synced)
  }

  @Test func syncStatusTransitionsToPendingToFailed() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = FailingAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submit(
      curriculumID: 42,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated
    )

    #expect(entry.syncStatus == .failed)
    #expect(entry.lastSyncAttempt != nil)
    #expect(try repository.fetch(id: entry.id)?.syncStatus == SyncStatus.failed)
  }

  // MARK: - Cloud Sync Enabled/Disabled Tests

  @Test func syncDoesNotOccurWhenCloudSyncDisabled() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = false
    let apiClient = TrackingAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submit(
      curriculumID: 42,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated
    )

    #expect(entry.syncStatus == SyncStatus.pending)
    #expect(apiClient.postCalls.count == 0)
    #expect(try repository.count() == 1)
  }

  @Test func syncOccursWhenCloudSyncEnabled() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = TrackingAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submit(
      curriculumID: 42,
      secondaryCurriculumID: 10,
      strategyID: 5,
      initiatedBy: .scheduled
    )

    #expect(apiClient.postCalls.count == 1)
    #expect(apiClient.postCalls[0].path == "/api/v1/journal")
    #expect(entry.syncStatus == SyncStatus.synced)
  }

  // MARK: - Server ID Persistence Tests

  @Test func serverIDPersistedAfterSuccessfulSync() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = SuccessfulAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submit(
      curriculumID: 42,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated
    )

    #expect(entry.serverId == 999)
    let storedEntry = try repository.fetch(id: entry.id)
    #expect(storedEntry?.serverId == 999)
  }
}

// MARK: - Test Doubles

/// API client that always succeeds with a mock response.
final class SuccessfulAPIClientSpy: APIClientProtocol {
  func get<T: Decodable>(_ path: String) async throws -> T {
    throw URLError(.badURL)
  }

  func post<T: Decodable>(_ path: String, body: some Encodable) async throws -> T {
    let response = JournalResponseModel(
      id: 999,
      curriculumID: 42,
      secondaryCurriculumID: 10,
      strategyID: 5,
      initiatedBy: .self_initiated
    )
    return response as! T
  }
}

/// API client that always fails.
final class FailingAPIClientSpy: APIClientProtocol {
  func get<T: Decodable>(_ path: String) async throws -> T {
    throw URLError(.badServerResponse)
  }

  func post<T: Decodable>(_ path: String, body: some Encodable) async throws -> T {
    throw URLError(.badServerResponse)
  }
}

/// API client that tracks calls without making network requests.
final class TrackingAPIClientSpy: APIClientProtocol {
  var postCalls: [(path: String, body: Any)] = []

  func get<T: Decodable>(_ path: String) async throws -> T {
    throw URLError(.badURL)
  }

  func post<T: Decodable>(_ path: String, body: some Encodable) async throws -> T {
    postCalls.append((path, body))
    let response = JournalResponseModel(
      id: 999,
      curriculumID: 42,
      secondaryCurriculumID: 10,
      strategyID: 5,
      initiatedBy: .self_initiated
    )
    return response as! T
  }
}

/// Repository that always fails on save.
final class FailingJournalRepository: JournalRepositoryProtocol {
  func save(_ entry: LocalJournalEntry) throws {
    throw JournalDatabaseError.failedToInsert("Simulated failure")
  }

  func update(_ entry: LocalJournalEntry) throws {
    throw JournalDatabaseError.failedToUpdate("Simulated failure")
  }

  func delete(id: UUID) throws {
    throw JournalDatabaseError.failedToDelete("Simulated failure")
  }

  func fetch(id: UUID) throws -> LocalJournalEntry? {
    nil
  }

  func fetchAll() throws -> [LocalJournalEntry] {
    []
  }

  func fetchPendingSync() throws -> [LocalJournalEntry] {
    []
  }

  func count() throws -> Int {
    0
  }
}
