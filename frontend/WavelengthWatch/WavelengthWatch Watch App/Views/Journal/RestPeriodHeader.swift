import SwiftUI

/// Supportive header shown on the review screen when the entry type is
/// `.rest`. Frames rest as honoring a natural contraction rather than an
/// emotion to log. ViewModel-free.
struct RestPeriodHeader: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "moon.zzz.fill")
        .font(.system(size: 36))
        .foregroundStyle(WLColorTokens.restAccent.opacity(0.8))
        .accessibilityHidden(true)

      Text("Your natural rhythm may be asking you to rest")
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity)
    .wlCardSurface(WLColorTokens.restAccent.opacity(0.1), cornerRadius: WLSpacingTokens.cardCornerRadius)
  }
}

#if DEBUG
#Preview("Rest Header") {
  RestPeriodHeader()
    .padding()
    .background(Color.black)
}
#endif
