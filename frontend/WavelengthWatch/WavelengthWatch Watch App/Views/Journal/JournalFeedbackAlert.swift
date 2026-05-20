import SwiftUI

/// Factory for the user-facing `Alert` that surfaces a
/// `ContentViewModel.JournalFeedback`. Centralizes the five-way switch
/// on `Kind` so the call site (currently `ContentView`'s alert modifier)
/// stays a one-liner.
enum JournalFeedbackAlert {
  /// Builds the alert for a given feedback record. The `dismiss` closure
  /// is invoked when the user taps the lone dismiss button; the caller
  /// typically uses it to clear the bound feedback state so the alert
  /// disappears.
  static func make(
    _ feedback: ContentViewModel.JournalFeedback,
    dismiss: @escaping () -> Void
  ) -> Alert {
    Alert(
      title: Text(title(for: feedback.kind)),
      message: Text(message(for: feedback.kind)),
      dismissButton: .default(Text("OK"), action: dismiss)
    )
  }

  /// The alert title copy for a feedback `Kind`. Extracted so the copy
  /// contract is unit-testable without introspecting an opaque `Alert`.
  static func title(for kind: ContentViewModel.JournalFeedback.Kind) -> String {
    switch kind {
    case .success: "Entry Logged"
    case .queued: "Saved Offline"
    case .syncing: "Syncing"
    case .syncSuccess: "Synced"
    case .failure: "Something went wrong"
    }
  }

  /// The alert message copy for a feedback `Kind`, including the
  /// entry-count pluralization for the `.syncing` and `.syncSuccess`
  /// cases. Extracted alongside `title(for:)` for unit testability.
  static func message(for kind: ContentViewModel.JournalFeedback.Kind) -> String {
    switch kind {
    case .success:
      "Thanks for checking in."
    case let .queued(message):
      message
    case let .syncing(current, total):
      "Syncing \(current) of \(total) entr\(pluralSuffix(for: total))…"
    case let .syncSuccess(count):
      "\(count) entr\(pluralSuffix(for: count)) synced successfully."
    case let .failure(message):
      message
    }
  }

  /// The "entr-" suffix: singular `y` for a count of 1, plural `ies`
  /// otherwise.
  private static func pluralSuffix(for count: Int) -> String {
    count == 1 ? "y" : "ies"
  }
}
