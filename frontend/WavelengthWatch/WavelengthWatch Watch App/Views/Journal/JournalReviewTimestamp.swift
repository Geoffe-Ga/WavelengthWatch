import SwiftUI

/// "Logged At" timestamp card displayed near the top of
/// `JournalReviewView`. Formats `Date()` at render time using a
/// medium-date + short-time style.
///
/// Extracted from `JournalReviewView` so the review body stays
/// composition-focused; the formatter is owned here instead of as a
/// static on the parent view.
struct JournalReviewTimestamp: View {
  /// Date to render. Defaults to `Date()` at construction so the
  /// timestamp captured by the view reflects roughly when the review
  /// appeared, matching the previous in-view behavior.
  let timestamp: Date

  init(timestamp: Date = Date()) {
    self.timestamp = timestamp
  }

  var body: some View {
    VStack(spacing: 4) {
      Text("Logged At")
        .font(.caption)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)

      Text(Self.formatter.string(from: timestamp))
        .font(.body)
        .foregroundStyle(.primary)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 12)
    .frame(maxWidth: .infinity)
    .background(WLColorTokens.elevatedCardFill)
    .cornerRadius(8)
  }

  private static let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
  }()
}

#if DEBUG
#Preview("Timestamp") {
  JournalReviewTimestamp()
    .padding()
    .background(Color.black)
}
#endif
