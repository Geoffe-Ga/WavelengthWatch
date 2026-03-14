import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

struct WLButtonStyleTests {
  @Test func primaryStyle_defaultTint_isAccentColor() {
    let style = WLPrimaryButtonStyle()
    #expect(style.tint == .accentColor)
  }

  @Test func primaryStyle_customTint_isPreserved() {
    let style = WLPrimaryButtonStyle(tint: .red)
    #expect(style.tint == .red)
  }

  @Test func secondaryStyle_defaultTint_isSecondary() {
    let style = WLSecondaryButtonStyle()
    #expect(style.tint == .secondary)
  }

  @Test func secondaryStyle_customTint_isPreserved() {
    let style = WLSecondaryButtonStyle(tint: .blue)
    #expect(style.tint == .blue)
  }
}
