import SwiftUI

/// Reusable error-state primitive for analytics screens: a warning icon, a
/// short heading, the failure message, and an optional retry action.
///
/// ViewModel-free — callers pass the message and (optionally) an async retry
/// closure. The retry button adopts the Liquid Glass primary button style
/// (`.glassProminent` on watchOS 26+, a tinted fallback otherwise). When
/// `retry` is nil the button is omitted, so the same primitive serves both
/// retryable failures (analytics detail views) and terminal ones (the journal
/// drill-down list).
struct AnalyticsErrorView: View {
  let message: String
  let retry: (() async -> Void)?

  /// Creates an error state.
  /// - Parameters:
  ///   - message: The user-facing failure description.
  ///   - retry: Optional async action; when provided, a "Retry" button is shown.
  init(message: String, retry: (() async -> Void)? = nil) {
    self.message = message
    self.retry = retry
  }

  var body: some View {
    VStack(spacing: WLSpacingTokens.paddingL) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 40))
        .foregroundColor(WLColorTokens.warningAccent)

      Text("Error")
        .font(.headline)
        .foregroundColor(WLColorTokens.primaryText)

      Text(message)
        .font(.caption)
        .foregroundColor(WLColorTokens.secondaryText)
        .multilineTextAlignment(.center)

      if let retry {
        Button("Retry") {
          Task { await retry() }
        }
        .wlPrimaryButtonStyle(tint: WLColorTokens.interactiveAccent)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 40)
    .padding(.horizontal, WLSpacingTokens.paddingL)
  }
}

// MARK: - Previews

#Preview("With retry") {
  AnalyticsErrorView(message: "Couldn't load your insights.", retry: {})
}

#Preview("Without retry") {
  AnalyticsErrorView(message: "No journal entries could be loaded.")
}
