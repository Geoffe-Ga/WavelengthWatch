import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

struct WLTypographyTokensTests {
  @Test func allFonts_areDefined() {
    let fonts: [Font] = [
      WLTypographyTokens.pageTitle,
      WLTypographyTokens.sectionHeader,
      WLTypographyTokens.cardTitle,
      WLTypographyTokens.cardTitleCompact,
      WLTypographyTokens.cardSubtitle,
      WLTypographyTokens.tag,
      WLTypographyTokens.contextLabel,
    ]
    #expect(fonts.count == 7)
  }

  @Test func sectionHeaderTracking_isPositive() {
    #expect(WLTypographyTokens.sectionHeaderTracking > 0)
  }

  @Test func fontWeights_areDefined() {
    let weights: [Font.Weight] = [
      WLTypographyTokens.pageTitleWeight,
      WLTypographyTokens.sectionHeaderWeight,
      WLTypographyTokens.cardTitleWeight,
      WLTypographyTokens.cardTitleCompactWeight,
      WLTypographyTokens.cardSubtitleWeight,
    ]
    #expect(weights.count == 5)
  }
}
