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
    switch feedback.kind {
    case .success:
      return Alert(
        title: Text("Entry Logged"),
        message: Text("Thanks for checking in."),
        dismissButton: .default(Text("OK"), action: dismiss)
      )
    case let .queued(message):
      return Alert(
        title: Text("Saved Offline"),
        message: Text(message),
        dismissButton: .default(Text("OK"), action: dismiss)
      )
    case let .syncing(current, total):
      let suffix = total == 1 ? "y" : "ies"
      return Alert(
        title: Text("Syncing"),
        message: Text("Syncing \(current) of \(total) entr\(suffix)…"),
        dismissButton: .default(Text("OK"), action: dismiss)
      )
    case let .syncSuccess(count):
      let suffix = count == 1 ? "y" : "ies"
      return Alert(
        title: Text("Synced"),
        message: Text("\(count) entr\(suffix) synced successfully."),
        dismissButton: .default(Text("OK"), action: dismiss)
      )
    case let .failure(message):
      return Alert(
        title: Text("Something went wrong"),
        message: Text(message),
        dismissButton: .default(Text("OK"), action: dismiss)
      )
    }
  }
}
