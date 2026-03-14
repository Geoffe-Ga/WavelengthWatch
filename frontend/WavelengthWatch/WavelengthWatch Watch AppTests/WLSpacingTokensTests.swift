import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

struct WLSpacingTokensTests {
  @Test func padding_isOrdered() {
    #expect(WLSpacingTokens.paddingXS < WLSpacingTokens.paddingS)
    #expect(WLSpacingTokens.paddingS < WLSpacingTokens.paddingM)
    #expect(WLSpacingTokens.paddingM < WLSpacingTokens.paddingL)
    #expect(WLSpacingTokens.paddingL < WLSpacingTokens.paddingXL)
  }

  @Test func cornerRadius_isOrdered() {
    #expect(WLSpacingTokens.cardCornerRadiusCompact < WLSpacingTokens.cardCornerRadiusSmall)
    #expect(WLSpacingTokens.cardCornerRadiusSmall < WLSpacingTokens.cardCornerRadius)
  }

  @Test func borderWidth_isPositive() {
    #expect(WLSpacingTokens.cardBorderWidth > 0)
  }

  @Test func allValues_arePositive() {
    let values: [CGFloat] = [
      WLSpacingTokens.paddingXS,
      WLSpacingTokens.paddingS,
      WLSpacingTokens.paddingM,
      WLSpacingTokens.paddingL,
      WLSpacingTokens.paddingXL,
      WLSpacingTokens.cardCornerRadius,
      WLSpacingTokens.cardCornerRadiusSmall,
      WLSpacingTokens.cardCornerRadiusCompact,
      WLSpacingTokens.cardPaddingStandard,
      WLSpacingTokens.cardPaddingCompact,
      WLSpacingTokens.indicatorDotSmall,
      WLSpacingTokens.indicatorDotMedium,
      WLSpacingTokens.listItemSpacing,
      WLSpacingTokens.sectionSpacing,
      WLSpacingTokens.cardContentSpacing,
    ]
    for value in values {
      #expect(value > 0)
    }
  }
}
