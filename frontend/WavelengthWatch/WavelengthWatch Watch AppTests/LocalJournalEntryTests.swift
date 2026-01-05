import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

struct LocalJournalEntryTests {
  @Test func createsEntryWithPendingSyncStatus() {
    let entry = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated
    )

    #expect(entry.syncStatus == .pending)
    #expect(entry.serverId == nil)
    #expect(entry.lastSyncAttempt == nil)
  }

  @Test func createsEntryWithOptionalFields() {
    let entry = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      secondaryCurriculumID: 2,
      strategyID: 3,
      initiatedBy: .scheduled
    )

    #expect(entry.secondaryCurriculumID == 2)
    #expect(entry.strategyID == 3)
    #expect(entry.initiatedBy == .scheduled)
  }

  @Test func syncedFactoryMethodSetsServerIDAndStatus() {
    let localEntry = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated
    )

    let response = JournalResponseModel(
      id: 456,
      curriculumID: 1,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated
    )

    let syncedEntry = LocalJournalEntry.synced(from: response, localEntry: localEntry)

    #expect(syncedEntry.serverId == 456)
    #expect(syncedEntry.syncStatus == .synced)
    #expect(syncedEntry.lastSyncAttempt != nil)
    #expect(syncedEntry.id == localEntry.id)
  }

  @Test func equatableComparesAllFields() {
    let date = Date()
    let entry1 = LocalJournalEntry(
      id: UUID(),
      createdAt: date,
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated
    )

    let entry2 = LocalJournalEntry(
      id: entry1.id,
      createdAt: date,
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated
    )

    #expect(entry1 == entry2)
  }

  @Test func hashableUsesID() {
    let id = UUID()
    let entry1 = LocalJournalEntry(
      id: id,
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated
    )

    let entry2 = LocalJournalEntry(
      id: id,
      createdAt: Date().addingTimeInterval(100),
      userID: 456,
      curriculumID: 2,
      initiatedBy: .scheduled
    )

    #expect(entry1.hashValue == entry2.hashValue)
  }

  @Test func codableEncodesAndDecodes() throws {
    let entry = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      secondaryCurriculumID: 2,
      strategyID: 3,
      initiatedBy: .scheduled
    )

    let data = try JSONEncoder().encode(entry)
    let decoded = try JSONDecoder().decode(LocalJournalEntry.self, from: data)

    #expect(decoded.id == entry.id)
    #expect(decoded.userID == entry.userID)
    #expect(decoded.curriculumID == entry.curriculumID)
    #expect(decoded.secondaryCurriculumID == entry.secondaryCurriculumID)
    #expect(decoded.strategyID == entry.strategyID)
    #expect(decoded.initiatedBy == entry.initiatedBy)
    #expect(decoded.syncStatus == entry.syncStatus)
  }
}
