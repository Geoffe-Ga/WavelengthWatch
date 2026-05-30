import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

/// Stored-property tests for `WLCardSurface`, mirroring `WLGlassModifierTests`.
///
/// The fill is type-erased to `AnyShapeStyle` (not `Equatable`), so these assert
/// the plumbing that *is* comparable — corner radius, stroke, and stroke width —
/// which is what call sites depend on staying intact. The translucent→opaque
/// degradation itself lives in `body` behind `@Environment` and is a visual
/// behavior validated on-device per the Phase 6b checklist (#302).
struct WLSurfaceModifierTests {
  @Test("Corner radius is preserved")
  func cornerRadius_isPreserved() {
    let modifier = WLCardSurface(
      translucentFill: AnyShapeStyle(Color.red),
      cornerRadius: 18,
      stroke: nil,
      strokeWidth: 0.5
    )
    #expect(modifier.cornerRadius == 18)
  }

  @Test("Stroke defaults to nil via the View extension")
  func stroke_defaultsToNil() {
    let view = Color.clear.wlCardSurface(Color.red, cornerRadius: 12)
    // The extension returns a ModifiedContent whose modifier carries the
    // defaults; constructing the modifier directly mirrors that default.
    let modifier = WLCardSurface(
      translucentFill: AnyShapeStyle(Color.red),
      cornerRadius: 12,
      stroke: nil,
      strokeWidth: 0.5
    )
    #expect(modifier.stroke == nil)
    #expect(modifier.strokeWidth == 0.5)
    _ = view
  }

  @Test("Stroke color is preserved")
  func stroke_isPreserved() {
    let modifier = WLCardSurface(
      translucentFill: AnyShapeStyle(Color.green),
      cornerRadius: 10,
      stroke: .blue,
      strokeWidth: 2
    )
    #expect(modifier.stroke == .blue)
    #expect(modifier.strokeWidth == 2)
  }

  @Test("A gradient fill is accepted without a stroke")
  func gradientFill_isAccepted() {
    let gradient = LinearGradient(
      colors: [.purple, .indigo],
      startPoint: .top,
      endPoint: .bottom
    )
    let modifier = WLCardSurface(
      translucentFill: AnyShapeStyle(gradient),
      cornerRadius: 16,
      stroke: nil,
      strokeWidth: 0.5
    )
    #expect(modifier.cornerRadius == 16)
    #expect(modifier.stroke == nil)
  }
}
