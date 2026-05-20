import Testing
@testable import WavelengthWatch_Watch_App

/// Copy and pluralization coverage for `JournalFeedbackAlert` (#325).
struct JournalFeedbackAlertTests {
  // MARK: - Titles

  @Test("each Kind maps to its design title")
  func title_perBranch() {
    #expect(JournalFeedbackAlert.title(for: .success) == "Entry Logged")
    #expect(JournalFeedbackAlert.title(for: .queued("x")) == "Saved Offline")
    #expect(JournalFeedbackAlert.title(for: .syncing(current: 1, total: 3)) == "Syncing")
    #expect(JournalFeedbackAlert.title(for: .syncSuccess(count: 2)) == "Synced")
    #expect(JournalFeedbackAlert.title(for: .failure("x")) == "Something went wrong")
  }

  // MARK: - Messages

  @Test("success and failure messages match design copy / pass through")
  func message_staticAndPassThrough() {
    #expect(JournalFeedbackAlert.message(for: .success) == "Thanks for checking in.")
    #expect(JournalFeedbackAlert.message(for: .queued("Saved for later")) == "Saved for later")
    #expect(JournalFeedbackAlert.message(for: .failure("Network unavailable")) == "Network unavailable")
  }

  // MARK: - Pluralization boundaries

  @Test("syncing message pluralizes on total")
  func message_syncingPluralization() {
    #expect(
      JournalFeedbackAlert.message(for: .syncing(current: 1, total: 1))
        == "Syncing 1 of 1 entry…"
    )
    #expect(
      JournalFeedbackAlert.message(for: .syncing(current: 1, total: 2))
        == "Syncing 1 of 2 entries…"
    )
  }

  @Test("syncSuccess message pluralizes on count")
  func message_syncSuccessPluralization() {
    #expect(
      JournalFeedbackAlert.message(for: .syncSuccess(count: 0))
        == "0 entries synced successfully."
    )
    #expect(
      JournalFeedbackAlert.message(for: .syncSuccess(count: 1))
        == "1 entry synced successfully."
    )
    #expect(
      JournalFeedbackAlert.message(for: .syncSuccess(count: 2))
        == "2 entries synced successfully."
    )
  }
}
