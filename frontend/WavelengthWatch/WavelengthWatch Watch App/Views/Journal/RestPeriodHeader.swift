import SwiftUI

/// Supportive header shown on the review screen when the entry type is
/// `.rest`. Frames rest as honoring a natural contraction rather than an
/// emotion to log. ViewModel-free.
struct RestPeriodHeader: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "moon.zzz.fill")
        .font(.system(size: 36))
        .foregroundStyle(.purple.opacity(0.8))
        .accessibilityHidden(true)

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
  RestPeriodHeader()
    .padding()
    .background(Color.black)
}
#endif
