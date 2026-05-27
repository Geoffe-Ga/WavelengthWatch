import SwiftUI

/// Supportive header shown above the review screen when the entry
/// type is `.rest`. Encourages the user instead of treating rest as
/// an emotion to log.
///
/// Extracted from `JournalReviewView` so the review screen's body
/// stays composition-focused; the rest-specific styling (moon icon,
/// purple tint, supportive copy) lives behind one named entry point.
struct JournalReviewRestHeader: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "moon.zzz.fill")
        .font(.system(size: 36))
        .foregroundStyle(.purple.opacity(0.8))

      Text("Your natural rhythm may be asking you to rest")
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: WLSpacingTokens.cardCornerRadius)
        .fill(Color.purple.opacity(0.1))
    )
  }
}

#if DEBUG
#Preview("Rest Header") {
  JournalReviewRestHeader()
    .padding()
    .background(Color.black)
}
#endif
