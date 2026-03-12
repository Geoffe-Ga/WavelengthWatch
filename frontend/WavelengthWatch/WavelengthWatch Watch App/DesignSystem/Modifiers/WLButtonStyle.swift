import SwiftUI

/// Primary action button style (Liquid Glass prominent or fallback).
///
/// Used for main CTAs like "Submit Entry", "Continue", etc.
/// On watchOS 26+ this will use `.glassProminent` button style.
struct WLPrimaryButtonStyle: ButtonStyle {
  let tint: Color

  init(tint: Color = .accentColor) {
    self.tint = tint
  }

  func makeBody(configuration: Configuration) -> some View {
    // TODO: watchOS 26 — Use .glassProminent style
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
      .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
  }
}

/// Secondary/subtle button style (Liquid Glass regular or fallback).
///
/// Used for less prominent actions, list items, option selectors.
struct WLSecondaryButtonStyle: ButtonStyle {
  let tint: Color

  init(tint: Color = .secondary) {
    self.tint = tint
  }

  func makeBody(configuration: Configuration) -> some View {
    // TODO: watchOS 26 — Use .glass style
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
      .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
  }
}

// MARK: - View Extensions

extension View {
  /// Applies the primary CTA button style.
  func wlPrimaryButtonStyle(tint: Color = .accentColor) -> some View {
    buttonStyle(WLPrimaryButtonStyle(tint: tint))
  }

  /// Applies the secondary button style.
  func wlSecondaryButtonStyle(tint: Color = .secondary) -> some View {
    buttonStyle(WLSecondaryButtonStyle(tint: tint))
  }
}
