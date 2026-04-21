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
      initiatedBy: .self_initiated,
      entryType: .emotion
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
      initiatedBy: .self_initiated,
      entryType: .emotion
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
      initiatedBy: .self_initiated,
      entryType: .emotion
    )
    let entry2 = LocalJournalEntry(
      createdAt: now,
      userID: 123,
      curriculumID: 2,
      initiatedBy: .self_initiated,
      entryType: .emotion
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
      initiatedBy: .self_initiated,
      entryType: .emotion
    )
    pending.syncStatus = .pending

    var failed = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 2,
      initiatedBy: .self_initiated,
      entryType: .emotion
    )
    failed.syncStatus = .failed

    var synced = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 3,
      initiatedBy: .self_initiated,
      entryType: .emotion
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
      initiatedBy: .self_initiated,
      entryType: .emotion
    ))
    try repo.save(LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 2,
      initiatedBy: .self_initiated,
      entryType: .emotion
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
      initiatedBy: .self_initiated,
      entryType: .emotion
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
      initiatedBy: .self_initiated,
      entryType: .emotion
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
      initiatedBy: .self_initiated,
      entryType: .emotion
    )
    let entry2 = LocalJournalEntry(
      createdAt: now,
      userID: 123,
      curriculumID: 2,
      initiatedBy: .self_initiated,
      entryType: .emotion
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
      initiatedBy: .self_initiated,
      entryType: .emotion
    )
    pending.syncStatus = .pending

    var failed = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 2,
      initiatedBy: .self_initiated,
      entryType: .emotion
    )
    failed.syncStatus = .failed

    var synced = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 3,
      initiatedBy: .self_initiated,
      entryType: .emotion
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
      initiatedBy: .self_initiated,
      entryType: .emotion
    ))
    try repo.save(LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 2,
      initiatedBy: .self_initiated,
      entryType: .emotion
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

  // MARK: - Date-Range Fetch Tests (Issue #259)

  @Test func inMemoryFetchByDateRangeFiltersOutsideWindow() throws {
    let repo = InMemoryJournalRepository()
    let now = Date()

    let inside = LocalJournalEntry(
      createdAt: now.addingTimeInterval(-3600),
      userID: 1,
      curriculumID: 10,
      initiatedBy: .self_initiated
    )
    let onStart = LocalJournalEntry(
      createdAt: now.addingTimeInterval(-7200),
      userID: 1,
      curriculumID: 20,
      initiatedBy: .self_initiated
    )
    let onEnd = LocalJournalEntry(
      createdAt: now,
      userID: 1,
      curriculumID: 30,
      initiatedBy: .self_initiated
    )
    let tooOld = LocalJournalEntry(
      createdAt: now.addingTimeInterval(-10_000),
      userID: 1,
      curriculumID: 40,
      initiatedBy: .self_initiated
    )
    let tooNew = LocalJournalEntry(
      createdAt: now.addingTimeInterval(60),
      userID: 1,
      curriculumID: 50,
      initiatedBy: .self_initiated
    )

    try repo.save(inside)
    try repo.save(onStart)
    try repo.save(onEnd)
    try repo.save(tooOld)
    try repo.save(tooNew)

    let windowStart = now.addingTimeInterval(-7200)
    let windowEnd = now
    let result = try repo.fetchByDateRange(from: windowStart, to: windowEnd)

    #expect(result.count == 3)
    #expect(result.contains { $0.id == inside.id })
    #expect(result.contains { $0.id == onStart.id })
    #expect(result.contains { $0.id == onEnd.id })
    #expect(!result.contains { $0.id == tooOld.id })
    #expect(!result.contains { $0.id == tooNew.id })
  }

  @Test func inMemoryFetchByDateRangeOrdersNewestFirst() throws {
    let repo = InMemoryJournalRepository()
    let base = Date()

    let oldest = LocalJournalEntry(
      createdAt: base.addingTimeInterval(-300),
      userID: 1,
      curriculumID: 1,
      initiatedBy: .self_initiated
    )
    let middle = LocalJournalEntry(
      createdAt: base.addingTimeInterval(-150),
      userID: 1,
      curriculumID: 2,
      initiatedBy: .self_initiated
    )
    let newest = LocalJournalEntry(
      createdAt: base,
      userID: 1,
      curriculumID: 3,
      initiatedBy: .self_initiated
    )

    try repo.save(middle)
    try repo.save(oldest)
    try repo.save(newest)

    let result = try repo.fetchByDateRange(
      from: base.addingTimeInterval(-3600),
      to: base.addingTimeInterval(3600)
    )

    #expect(result.count == 3)
    #expect(result[0].id == newest.id)
    #expect(result[1].id == middle.id)
    #expect(result[2].id == oldest.id)
  }

  @Test func sqliteFetchByDateRangeReturnsOnlyEntriesInRange() throws {
    let tempPath = NSTemporaryDirectory() + UUID().uuidString + ".db"
    let db = JournalDatabase(path: tempPath)
    let repo = JournalRepository(database: db)
    let now = Date()

    let inWindow = LocalJournalEntry(
      createdAt: now.addingTimeInterval(-3600),
      userID: 1,
      curriculumID: 10,
      initiatedBy: .self_initiated
    )
    let outOfWindow = LocalJournalEntry(
      createdAt: now.addingTimeInterval(-86_400),
      userID: 1,
      curriculumID: 20,
      initiatedBy: .self_initiated
    )

    try repo.save(inWindow)
    try repo.save(outOfWindow)

    let windowStart = now.addingTimeInterval(-7200)
    let windowEnd = now
    let result = try repo.fetchByDateRange(from: windowStart, to: windowEnd)

    #expect(result.count == 1)
    #expect(result[0].id == inWindow.id)

    do {
      try FileManager.default.removeItem(atPath: tempPath)
    } catch {
      print("⚠️ Test cleanup failed to remove temp database at \(tempPath): \(error)")
    }
  }

  @Test func sqliteFetchByDateRangeSupportsInclusiveBoundaries() throws {
    let tempPath = NSTemporaryDirectory() + UUID().uuidString + ".db"
    let db = JournalDatabase(path: tempPath)
    let repo = JournalRepository(database: db)
    let windowStart = Date(timeIntervalSince1970: 1_700_000_000)
    let windowEnd = windowStart.addingTimeInterval(3600)

    let startEntry = LocalJournalEntry(
      createdAt: windowStart,
      userID: 1,
      curriculumID: 1,
      initiatedBy: .self_initiated
    )
    let endEntry = LocalJournalEntry(
      createdAt: windowEnd,
      userID: 1,
      curriculumID: 2,
      initiatedBy: .self_initiated
    )

    try repo.save(startEntry)
    try repo.save(endEntry)

    let result = try repo.fetchByDateRange(from: windowStart, to: windowEnd)
    #expect(result.count == 2)

    do {
      try FileManager.default.removeItem(atPath: tempPath)
    } catch {
      print("⚠️ Test cleanup failed to remove temp database at \(tempPath): \(error)")
    }
  }

  // MARK: - Index + Migration Tests (Issue #259)

  @Test func sqliteSchemaVersionIsAtLeastFour() {
    #expect(JournalDatabase.schemaVersion >= 4)
  }

  @Test func sqliteCreatesStrategyAndCompositeIndexes() throws {
    let tempPath = NSTemporaryDirectory() + UUID().uuidString + ".db"
    let db = JournalDatabase(path: tempPath)
    try db.open()

    let indexes = try db.listIndexes()

    #expect(indexes.contains("idx_journal_strategy"))
    #expect(indexes.contains("idx_journal_created_curriculum"))

    db.close()
    do {
      try FileManager.default.removeItem(atPath: tempPath)
    } catch {
      print("⚠️ Test cleanup failed to remove temp database at \(tempPath): \(error)")
    }
  }

  /// Simulates opening a v3 database (no analytics indexes) and verifies that
  /// `migrateToV4` backfills the new indexes and preserves existing data.
  @Test func sqliteMigratesV3DatabaseToV4PreservingData() throws {
    let tempPath = NSTemporaryDirectory() + UUID().uuidString + ".db"

    // Seed: open once to create the schema, insert an entry, then drop the
    // v4 indexes and rewind schema_version to 3 to mimic an upgrade.
    let seedDB = JournalDatabase(path: tempPath)
    try seedDB.open()
    let seedEntry = LocalJournalEntry(
      createdAt: Date(timeIntervalSince1970: 1_700_000_000),
      userID: 7,
      curriculumID: 42,
      initiatedBy: .self_initiated
    )
    try seedDB.insert(seedEntry)
    try seedDB.execRaw("DROP INDEX IF EXISTS idx_journal_strategy")
    try seedDB.execRaw("DROP INDEX IF EXISTS idx_journal_created_curriculum")
    try seedDB.execRaw("UPDATE schema_version SET version = 3")
    seedDB.close()

    // Reopen: this should run migrateToV4 and add the missing indexes.
    let upgradedDB = JournalDatabase(path: tempPath)
    try upgradedDB.open()

    let indexes = try upgradedDB.listIndexes()
    #expect(indexes.contains("idx_journal_strategy"))
    #expect(indexes.contains("idx_journal_created_curriculum"))

    // Existing data survives the migration.
    let repo = JournalRepository(database: upgradedDB)
    let fetched = try repo.fetch(id: seedEntry.id)
    #expect(fetched?.id == seedEntry.id)
    #expect(fetched?.curriculumID == 42)

    upgradedDB.close()
    do {
      try FileManager.default.removeItem(atPath: tempPath)
    } catch {
      print("⚠️ Test cleanup failed to remove temp database at \(tempPath): \(error)")
    }
  }
}
