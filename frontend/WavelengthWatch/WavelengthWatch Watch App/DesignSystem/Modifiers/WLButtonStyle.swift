import SwiftUI

/// Primary action button style — fallback for pre-watchOS-26 runtimes.
///
/// Used for main CTAs like "Submit Entry", "Continue", etc. On watchOS 26+
/// the `wlPrimaryButtonStyle(tint:)` extension routes to the system
/// `.glassProminent` style instead; this struct stays as the older-OS path
/// and is still useful directly (e.g., in tests).
struct WLPrimaryButtonStyle: ButtonStyle {
  let tint: Color

  init(tint: Color = .accentColor) {
    self.tint = tint
  }

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(WLTypographyTokens.cardTitle)
      .fontWeight(.semibold)
      .foregroundColor(.white)
      .padding(.horizontal, WLSpacingTokens.paddingL)
      .padding(.vertical, WLSpacingTokens.paddingS)
      .frame(maxWidth: .infinity)
      .background(
        RoundedRectangle(cornerRadius: WLSpacingTokens.cardCornerRadius)
          .fill(tint.opacity(configuration.isPressed ? 0.5 : 0.8))
      )
      .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
      .wlAnimation(.easeInOut(duration: 0.15), value: configuration.isPressed)
  }
}

/// Secondary/subtle button style — fallback for pre-watchOS-26 runtimes.
///
/// Used for less prominent actions, list items, option selectors. On
/// watchOS 26+ the `wlSecondaryButtonStyle(tint:)` extension routes to the
/// system `.glass` style instead.
struct WLSecondaryButtonStyle: ButtonStyle {
  let tint: Color

  init(tint: Color = .secondary) {
    self.tint = tint
  }

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundColor(.white)
      .padding(.horizontal, WLSpacingTokens.paddingM)
      .padding(.vertical, WLSpacingTokens.paddingS)
      .background(
        RoundedRectangle(cornerRadius: WLSpacingTokens.cardCornerRadiusSmall)
          .fill(tint.opacity(configuration.isPressed ? 0.2 : 0.1))
          .overlay(
            RoundedRectangle(cornerRadius: WLSpacingTokens.cardCornerRadiusSmall)
              .stroke(
                Color.white.opacity(0.1),
                lineWidth: WLSpacingTokens.cardBorderWidth
              )
          )
      )
      .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
      .wlAnimation(.easeInOut(duration: 0.15), value: configuration.isPressed)
  }
}

// MARK: - View Extensions

extension View {
  /// Applies the primary CTA button style. Picks `.glassProminent` on
  /// watchOS 26+, falls back to `WLPrimaryButtonStyle` otherwise.
  @ViewBuilder
  func wlPrimaryButtonStyle(tint: Color = .accentColor) -> some View {
    if #available(watchOS 26, *) {
      buttonStyle(.glassProminent).tint(tint)
    } else {
      buttonStyle(WLPrimaryButtonStyle(tint: tint))
    }
  }

  /// Applies the secondary button style. Picks `.glass` on watchOS 26+,
  /// falls back to `WLSecondaryButtonStyle` otherwise.
  @ViewBuilder
  func wlSecondaryButtonStyle(tint: Color = .secondary) -> some View {
    if #available(watchOS 26, *) {
      buttonStyle(.glass).tint(tint)
    } else {
      buttonStyle(WLSecondaryButtonStyle(tint: tint))
    }
  }
}
