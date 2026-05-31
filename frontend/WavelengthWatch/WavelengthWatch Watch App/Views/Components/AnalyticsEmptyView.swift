import SwiftUI

/// Reusable empty-state placeholder for analytics screens: an icon, a title,
/// and an optional supporting message.
///
/// Two prominence levels consolidate the previously per-file empty states:
/// `.compact` for the inline per-section "no data" placeholders, and
/// `.prominent` for the top-level overview "start logging" state (larger icon,
/// headline title, accent tint). ViewModel-free; the icon + text read as a
/// single VoiceOver element.
struct AnalyticsEmptyView: View {
  enum Prominence {
    case compact
    case prominent
  }

  let systemImage: String
  let title: String
  let message: String?
  let prominence: Prominence

  init(
    systemImage: String,
    title: String,
    message: String? = nil,
    prominence: Prominence = .compact
  ) {
    self.systemImage = systemImage
    self.title = title
    self.message = message
    self.prominence = prominence
  }

  var body: some View {
    VStack(spacing: spacing) {
      Image(systemName: systemImage)
        .font(iconFont)
        .foregroundColor(iconColor)
        .accessibilityHidden(true)

      Text(title)
        .font(titleFont)
        .foregroundColor(titleColor)

      if let message {
        Text(message)
          .font(.caption)
          .foregroundColor(WLColorTokens.labelText)
          .multilineTextAlignment(.center)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.top, topPadding)
    .padding(.bottom, bottomPadding)
    .accessibilityElement(children: .combine)
  }

  // MARK: - Prominence-driven styling

  private var spacing: CGFloat {
    prominence == .prominent ? WLSpacingTokens.paddingL : WLSpacingTokens.paddingS
  }

  private var iconFont: Font {
    prominence == .prominent ? .system(size: 48) : .title
  }

  private var iconColor: Color {
    prominence == .prominent
      ? WLColorTokens.interactiveAccent.opacity(0.6)
      : WLColorTokens.labelText
  }

  private var titleFont: Font {
    prominence == .prominent ? .headline : .caption
  }

  private var titleColor: Color {
    prominence == .prominent ? WLColorTokens.primaryText : WLColorTokens.labelText
  }

  private var topPadding: CGFloat {
    prominence == .prominent ? 40 : WLSpacingTokens.paddingXL
  }

  private var bottomPadding: CGFloat {
    prominence == .prominent ? 0 : WLSpacingTokens.paddingXL
  }
}

// MARK: - Previews

#Preview("Compact") {
  AnalyticsEmptyView(systemImage: "chart.bar.xaxis", title: "No data")
}

#Preview("Compact with message") {
  AnalyticsEmptyView(
    systemImage: "tray",
    title: "No entries yet",
    message: "Logged entries that match this filter will appear here."
  )
}

#Preview("Prominent") {
  AnalyticsEmptyView(
    systemImage: "chart.bar",
    title: "No Data Yet",
    message: "Start logging your emotions to see insights and patterns.",
    prominence: .prominent
  )
}
