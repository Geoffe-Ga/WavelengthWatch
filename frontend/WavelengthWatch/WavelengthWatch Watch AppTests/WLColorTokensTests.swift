import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

struct WLColorTokensTests {
  @Test func namedLayerColors_areNotNil() {
    let colors: [Color] = [
      WLColorTokens.beige,
      WLColorTokens.purple,
      WLColorTokens.red,
      WLColorTokens.blue,
      WLColorTokens.orange,
      WLColorTokens.green,
      WLColorTokens.yellow,
      WLColorTokens.teal,
      WLColorTokens.ultraviolet,
      WLColorTokens.clearLight,
      WLColorTokens.strategies,
    ]
    #expect(colors.count == 11)
  }

  @Test func layerFunction_delegatesToColorStage() {
    // Known mapping: "Red" -> .red (Color+Stage uses capitalized names)
    let color = WLColorTokens.layer("Red")
    #expect(color == Color.red)
  }

  @Test func layerFunction_unknownName_returnsGray() {
    let color = WLColorTokens.layer("nonexistent")
    #expect(color == Color.gray)
  }

  @Test func surfaceOpacities_areOrdered() {
    #expect(WLColorTokens.surfaceOpacitySubtle < WLColorTokens.surfaceOpacityLow)
    #expect(WLColorTokens.surfaceOpacityLow < WLColorTokens.surfaceOpacityMedium)
    #expect(WLColorTokens.surfaceOpacityMedium < WLColorTokens.surfaceOpacityHigh)
  }

  @Test func surfaceOpacities_areInValidRange() {
    let opacities = [
      WLColorTokens.surfaceOpacitySubtle,
      WLColorTokens.surfaceOpacityLow,
      WLColorTokens.surfaceOpacityMedium,
      WLColorTokens.surfaceOpacityHigh,
    ]
    for opacity in opacities {
      #expect(opacity > 0 && opacity <= 1.0)
    }
  }

  @Test func semanticColors_areDefined() {
    // Verify semantic colors exist (compile-time check mostly, but validates they're accessible)
    _ = WLColorTokens.cardFill
    _ = WLColorTokens.elevatedCardFill
    _ = WLColorTokens.primaryText
    _ = WLColorTokens.secondaryText
    _ = WLColorTokens.tertiaryText
    _ = WLColorTokens.labelText
  }

  @Test func cardFillTinted_producesColor() {
    let tinted = WLColorTokens.cardFill(tinted: .blue)
    #expect(tinted != Color.clear)
  }
}
