import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

struct JournalRepositoryTests {
  // MARK: - InMemoryRepository Tests

  @Test func inMemorySavesEntry() throws {
    let repo = InMemoryJournalRepository()
    let entry = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated
    )

    try repo.save(entry)
    let fetched = try repo.fetch(id: entry.id)

    #expect(fetched?.id == entry.id)
    #expect(fetched?.curriculumID == entry.curriculumID)
  }

  @Test func inMemoryUpdatesEntry() throws {
    let repo = InMemoryJournalRepository()
    var entry = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated
    )

    try repo.save(entry)

    entry.syncStatus = .synced
    entry.serverId = 456
    try repo.update(entry)

    let fetched = try repo.fetch(id: entry.id)
    #expect(fetched?.syncStatus == .synced)
    #expect(fetched?.serverId == 456)
  }

  @Test func inMemoryDeletesEntry() throws {
    let repo = InMemoryJournalRepository()
    let entry = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated
    )

    try repo.save(entry)
    try repo.delete(id: entry.id)

    let fetched = try repo.fetch(id: entry.id)
    #expect(fetched == nil)
  }

  @Test func inMemoryFetchAllReturnsNewestFirst() throws {
    let repo = InMemoryJournalRepository()
    let now = Date()

    let entry1 = LocalJournalEntry(
      createdAt: now.addingTimeInterval(-100),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated
    )
    let entry2 = LocalJournalEntry(
      createdAt: now,
      userID: 123,
      curriculumID: 2,
      initiatedBy: .self_initiated
    )

    try repo.save(entry1)
    try repo.save(entry2)

    let all = try repo.fetchAll()
    #expect(all.count == 2)
    #expect(all[0].id == entry2.id)
    #expect(all[1].id == entry1.id)
  }

  @Test func inMemoryFetchPendingSyncReturnsPendingAndFailed() throws {
    let repo = InMemoryJournalRepository()

    var pending = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated
    )
    pending.syncStatus = .pending

    var failed = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 2,
      initiatedBy: .self_initiated
    )
    failed.syncStatus = .failed

    var synced = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 3,
      initiatedBy: .self_initiated
    )
    synced.syncStatus = .synced

    try repo.save(pending)
    try repo.save(failed)
    try repo.save(synced)

    let pendingEntries = try repo.fetchPendingSync()
    #expect(pendingEntries.count == 2)
    #expect(pendingEntries.contains { $0.id == pending.id })
    #expect(pendingEntries.contains { $0.id == failed.id })
  }

  @Test func inMemoryCountReturnsCorrectNumber() throws {
    let repo = InMemoryJournalRepository()

    try repo.save(LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated
    ))
    try repo.save(LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 2,
      initiatedBy: .self_initiated
    ))

    let count = try repo.count()
    #expect(count == 2)
  }

  @Test func inMemoryClearRemovesAllEntries() throws {
    let repo = InMemoryJournalRepository()

    try repo.save(LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated
    ))

    repo.clear()

    let count = try repo.count()
    #expect(count == 0)
  }

  // MARK: - SQLite Repository Tests

  @Test func sqliteSavesAndFetchesEntry() throws {
    let tempPath = NSTemporaryDirectory() + UUID().uuidString + ".db"
    let db = JournalDatabase(path: tempPath)
    let repo = JournalRepository(database: db)

    let entry = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      secondaryCurriculumID: 2,
      strategyID: 3,
      initiatedBy: .scheduled
    )

    try repo.save(entry)
    let fetched = try repo.fetch(id: entry.id)

    #expect(fetched?.id == entry.id)
    #expect(fetched?.userID == entry.userID)
    #expect(fetched?.curriculumID == entry.curriculumID)
    #expect(fetched?.secondaryCurriculumID == entry.secondaryCurriculumID)
    #expect(fetched?.strategyID == entry.strategyID)
    #expect(fetched?.initiatedBy == entry.initiatedBy)
    #expect(fetched?.syncStatus == .pending)

    // Cleanup
    do {
      try FileManager.default.removeItem(atPath: tempPath)
    } catch {
      print("⚠️ Test cleanup failed to remove temp database at \(tempPath): \(error)")
    }
  }

  @Test func sqliteUpdatesEntry() throws {
    let tempPath = NSTemporaryDirectory() + UUID().uuidString + ".db"
    let db = JournalDatabase(path: tempPath)
    let repo = JournalRepository(database: db)

    var entry = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated
    )

    try repo.save(entry)

    entry.syncStatus = .synced
    entry.serverId = 456
    try repo.update(entry)

    let fetched = try repo.fetch(id: entry.id)
    #expect(fetched?.syncStatus == .synced)
    #expect(fetched?.serverId == 456)

    // Cleanup
    do {
      try FileManager.default.removeItem(atPath: tempPath)
    } catch {
      print("⚠️ Test cleanup failed to remove temp database at \(tempPath): \(error)")
    }
  }

  @Test func sqliteDeletesEntry() throws {
    let tempPath = NSTemporaryDirectory() + UUID().uuidString + ".db"
    let db = JournalDatabase(path: tempPath)
    let repo = JournalRepository(database: db)

    let entry = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated
    )

    try repo.save(entry)
    try repo.delete(id: entry.id)

    let fetched = try repo.fetch(id: entry.id)
    #expect(fetched == nil)

    // Cleanup
    do {
      try FileManager.default.removeItem(atPath: tempPath)
    } catch {
      print("⚠️ Test cleanup failed to remove temp database at \(tempPath): \(error)")
    }
  }

  @Test func sqliteFetchAllReturnsNewestFirst() throws {
    let tempPath = NSTemporaryDirectory() + UUID().uuidString + ".db"
    let db = JournalDatabase(path: tempPath)
    let repo = JournalRepository(database: db)
    let now = Date()

    let entry1 = LocalJournalEntry(
      createdAt: now.addingTimeInterval(-100),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated
    )
    let entry2 = LocalJournalEntry(
      createdAt: now,
      userID: 123,
      curriculumID: 2,
      initiatedBy: .self_initiated
    )

    try repo.save(entry1)
    try repo.save(entry2)

    let all = try repo.fetchAll()
    #expect(all.count == 2)
    #expect(all[0].id == entry2.id)
    #expect(all[1].id == entry1.id)

    // Cleanup
    do {
      try FileManager.default.removeItem(atPath: tempPath)
    } catch {
      print("⚠️ Test cleanup failed to remove temp database at \(tempPath): \(error)")
    }
  }

  @Test func sqliteFetchPendingSyncReturnsPendingAndFailed() throws {
    let tempPath = NSTemporaryDirectory() + UUID().uuidString + ".db"
    let db = JournalDatabase(path: tempPath)
    let repo = JournalRepository(database: db)

    var pending = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated
    )
    pending.syncStatus = .pending

    var failed = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 2,
      initiatedBy: .self_initiated
    )
    failed.syncStatus = .failed

    var synced = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 3,
      initiatedBy: .self_initiated
    )
    synced.syncStatus = .synced

    try repo.save(pending)
    try repo.save(failed)
    try repo.save(synced)

    try repo.update(failed)
    try repo.update(synced)

    let pendingEntries = try repo.fetchPendingSync()
    #expect(pendingEntries.count == 2)
    #expect(pendingEntries.contains { $0.id == pending.id })
    #expect(pendingEntries.contains { $0.id == failed.id })

    // Cleanup
    do {
      try FileManager.default.removeItem(atPath: tempPath)
    } catch {
      print("⚠️ Test cleanup failed to remove temp database at \(tempPath): \(error)")
    }
  }

  @Test func sqliteCountReturnsCorrectNumber() throws {
    let tempPath = NSTemporaryDirectory() + UUID().uuidString + ".db"
    let db = JournalDatabase(path: tempPath)
    let repo = JournalRepository(database: db)

    try repo.save(LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated
    ))
    try repo.save(LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 2,
      initiatedBy: .self_initiated
    ))

    let count = try repo.count()
    #expect(count == 2)

    // Cleanup
    do {
      try FileManager.default.removeItem(atPath: tempPath)
    } catch {
      print("⚠️ Test cleanup failed to remove temp database at \(tempPath): \(error)")
    }
  }
}
