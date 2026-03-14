import SwiftUI

/// Typography tokens for consistent text styling.
///
/// Each token represents a semantic text role (page title,
/// section header, body, caption, etc.) rather than a raw font size.
enum WLTypographyTokens {
  // MARK: - Page-Level

  /// Page/section title (e.g., phase name hero text)
  static let pageTitle: Font = .title3
  static let pageTitleWeight: Font.Weight = .medium

  /// Section header (e.g., "MEDICINAL", "STRATEGIES")
  static let sectionHeader: Font = .caption
  static let sectionHeaderWeight: Font.Weight = .medium
  static let sectionHeaderTracking: CGFloat = 1.5

  // MARK: - Card-Level

  /// Card title (expression text)
  static let cardTitle: Font = .body
  static let cardTitleWeight: Font.Weight = .medium

  /// Card title in compact mode
  static let cardTitleCompact: Font = .body
  static let cardTitleCompactWeight: Font.Weight = .bold

  /// Card subtitle / context text
  static let cardSubtitle: Font = .caption
  static let cardSubtitleWeight: Font.Weight = .medium

  // MARK: - Supporting

  /// Tag / badge text
  static let tag: Font = .caption2

  /// Layer context label
  static let contextLabel: Font = .caption2
}
