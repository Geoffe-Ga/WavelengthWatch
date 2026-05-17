import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

struct WLGlassModifierTests {
  @Test func defaultIntensity_isRegular() {
    let modifier = WLGlassModifier()
    #expect(modifier.intensity == .regular)
  }

  @Test func prominentIntensity_isDistinct() {
    let regular = WLGlassModifier(intensity: .regular)
    let prominent = WLGlassModifier(intensity: .prominent)
    #expect(regular.intensity != prominent.intensity)
  }

  @Test func defaultCornerRadius_matchesToken() {
    let modifier = WLGlassModifier()
    #expect(modifier.cornerRadius == WLSpacingTokens.cardCornerRadius)
  }

  @Test func customCornerRadius_isPreserved() {
    let modifier = WLGlassModifier(cornerRadius: 20)
    #expect(modifier.cornerRadius == 20)
  }

  @Test func tint_defaultsToNil() {
    let modifier = WLGlassModifier()
    #expect(modifier.tint == nil)
  }

  @Test func tint_isPreserved() {
    let modifier = WLGlassModifier(tint: .blue)
    #expect(modifier.tint == .blue)
  }

  @Test func glassAvailable_tracksRuntimeSDK() {
    // The build now targets the watchOS 26 SDK (Xcode 26), so Glass APIs
    // resolve at runtime against `if #available(watchOS 26, *)`. On a
    // watchOS 26+ simulator the flag is true; on older runtimes it stays
    // false and modifiers fall back automatically.
    if #available(watchOS 26, *) {
      #expect(WLTheme.isGlassAvailable == true)
    } else {
      #expect(WLTheme.isGlassAvailable == false)
    }
  }
}
