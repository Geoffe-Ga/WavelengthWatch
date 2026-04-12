import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

struct WLCardModifierTests {
  @Test func defaultCard_hasNoTint() {
    let modifier = WLCardModifier()
    #expect(modifier.tint == nil)
  }

  @Test func defaultCard_isNotCompact() {
    let modifier = WLCardModifier()
    #expect(modifier.isCompact == false)
  }

  @Test func tintedCard_preservesTint() {
    let modifier = WLCardModifier(tint: .red)
    #expect(modifier.tint == .red)
  }

  @Test func compactCard_isCompact() {
    let modifier = WLCardModifier(isCompact: true)
    #expect(modifier.isCompact == true)
  }
}
