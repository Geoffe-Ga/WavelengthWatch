import Testing
@testable import WavelengthWatch_Watch_App

/// Coverage for `RootPresentationHost`'s pure message composition. The host
/// itself is a `ViewModifier` (not unit-testable in isolation), but the
/// storage-error copy is built by a static helper so the diagnostic-reason
/// threading (#457 storage RCA) can be verified without rendering.
struct RootPresentationHostTests {
  /// The user-facing guidance must always be present, reason or not.
  private let userGuidance = "entries logged this session won't be saved"

  @Test("storage-error message is the plain user copy when there is no reason")
  func storageErrorMessage_withoutReason_isPlainCopy() {
    let message = RootPresentationHost.storageErrorMessage(reason: nil)
    #expect(message.contains(userGuidance))
    // No diagnostic block when there's nothing to diagnose.
    #expect(!message.contains("Details:"))
  }

  @Test("an empty reason is treated as no reason")
  func storageErrorMessage_withEmptyReason_isPlainCopy() {
    let message = RootPresentationHost.storageErrorMessage(reason: "")
    #expect(message.contains(userGuidance))
    #expect(!message.contains("Details:"))
  }

  @Test("storage-error message appends the failure reason verbatim for diagnostics")
  func storageErrorMessage_withReason_includesItVerbatim() {
    let reason = "open failed: unable to open database file"
    let message = RootPresentationHost.storageErrorMessage(reason: reason)
    // Both the human guidance and the exact SQLite reason must be readable
    // straight off the watch screen.
    #expect(message.contains(userGuidance))
    #expect(message.contains(reason))
  }
}
