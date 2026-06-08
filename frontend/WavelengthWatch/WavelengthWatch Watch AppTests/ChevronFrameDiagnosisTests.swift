import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

/// TEMPORARY (#457 Phase 0.1): unit coverage for the chevron-frame classifier
/// that the cold-start instrumentation logs. Remove alongside the rest of the
/// Phase 0 diagnostics once the RCA lands.
///
/// The classifier is the bit of real logic in the instrumentation — it turns a
/// resolved global frame into a verdict that tells a *layout* failure
/// (off-screen / zero-size) apart from a *compositing* failure (a correct,
/// on-screen frame that still never paints).
struct ChevronFrameDiagnosisTests {
  private let screen = CGRect(x: 0, y: 0, width: 184, height: 224)

  @Test("a centred, sized frame reads as onscreen")
  func onscreen() {
    let chevron = CGRect(x: 140, y: 180, width: 32, height: 32)
    #expect(
      ChevronFrameDiagnosis.classify(chevron: chevron, container: screen)
        == .onscreen
    )
  }

  @Test("a zero-size frame reads as zeroSize even when positioned onscreen")
  func zeroSize() {
    let chevron = CGRect(x: 140, y: 180, width: 0, height: 0)
    #expect(
      ChevronFrameDiagnosis.classify(chevron: chevron, container: screen)
        == .zeroSize
    )
  }

  @Test("a frame entirely below the screen reads as offscreenBelow")
  func offscreenBelow() {
    let chevron = CGRect(x: 140, y: 240, width: 32, height: 32)
    #expect(
      ChevronFrameDiagnosis.classify(chevron: chevron, container: screen)
        == .offscreenBelow
    )
  }

  @Test("a frame entirely above the screen reads as offscreenAbove")
  func offscreenAbove() {
    let chevron = CGRect(x: 140, y: -64, width: 32, height: 32)
    #expect(
      ChevronFrameDiagnosis.classify(chevron: chevron, container: screen)
        == .offscreenAbove
    )
  }

  @Test("a frame past the horizontal edge reads as offscreenSide")
  func offscreenSide() {
    let chevron = CGRect(x: 184, y: 180, width: 32, height: 32)
    #expect(
      ChevronFrameDiagnosis.classify(chevron: chevron, container: screen)
        == .offscreenSide
    )
  }

  @Test("an empty screen rect is indeterminate, not a false offscreen")
  func indeterminate() {
    let chevron = CGRect(x: 140, y: 180, width: 32, height: 32)
    #expect(
      ChevronFrameDiagnosis.classify(chevron: chevron, container: .zero)
        == .indeterminate
    )
  }

  @Test("a frame straddling the bottom edge still counts as onscreen")
  func straddlingBottomEdgeIsOnscreen() {
    // maxY past the edge but minY still within: partially visible => onscreen.
    let chevron = CGRect(x: 140, y: 210, width: 32, height: 32)
    #expect(
      ChevronFrameDiagnosis.classify(chevron: chevron, container: screen)
        == .onscreen
    )
  }
}
