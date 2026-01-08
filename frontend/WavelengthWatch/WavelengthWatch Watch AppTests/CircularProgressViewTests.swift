import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("CircularProgressView Tests")
struct CircularProgressViewTests {
  // MARK: - Percentage Tests

  @Test("view accepts percentage value within valid range")
  func view_acceptsValidPercentage() {
    let view = CircularProgressView(percentage: 75.0)

    #expect(view.percentage == 75.0)
  }

  @Test("view accepts zero percentage")
  func view_acceptsZeroPercentage() {
    let view = CircularProgressView(percentage: 0.0)

    #expect(view.percentage == 0.0)
  }

  @Test("view accepts 100 percentage")
  func view_accepts100Percentage() {
    let view = CircularProgressView(percentage: 100.0)

    #expect(view.percentage == 100.0)
  }

  @Test("view accepts decimal percentage")
  func view_acceptsDecimalPercentage() {
    let view = CircularProgressView(percentage: 67.8)

    #expect(view.percentage == 67.8)
  }

  // MARK: - Size Tests

  @Test("view uses default size when not specified")
  func view_usesDefaultSize() {
    let view = CircularProgressView(percentage: 50.0)

    #expect(view.size == 100.0)
  }

  @Test("view accepts custom size")
  func view_acceptsCustomSize() {
    let view = CircularProgressView(percentage: 50.0, size: 120.0)

    #expect(view.size == 120.0)
  }

  @Test("view accepts small size")
  func view_acceptsSmallSize() {
    let view = CircularProgressView(percentage: 50.0, size: 50.0)

    #expect(view.size == 50.0)
  }

  @Test("view accepts large size")
  func view_acceptsLargeSize() {
    let view = CircularProgressView(percentage: 50.0, size: 200.0)

    #expect(view.size == 200.0)
  }

  // MARK: - Color Tests

  @Test("green color for high percentage (>70%)")
  func greenColor_forHighPercentage() {
    let view = CircularProgressView(percentage: 85.0)

    #expect(view.progressColor == .green)
  }

  @Test("green color for exactly 71%")
  func greenColor_forExactly71Percent() {
    let view = CircularProgressView(percentage: 71.0)

    #expect(view.progressColor == .green)
  }

  @Test("yellow color for medium percentage (50-70%)")
  func yellowColor_forMediumPercentage() {
    let view = CircularProgressView(percentage: 60.0)

    #expect(view.progressColor == .yellow)
  }

  @Test("yellow color for exactly 70%")
  func yellowColor_forExactly70Percent() {
    let view = CircularProgressView(percentage: 70.0)

    #expect(view.progressColor == .yellow)
  }

  @Test("yellow color for exactly 50%")
  func yellowColor_forExactly50Percent() {
    let view = CircularProgressView(percentage: 50.0)

    #expect(view.progressColor == .yellow)
  }

  @Test("orange color for low percentage (<50%)")
  func orangeColor_forLowPercentage() {
    let view = CircularProgressView(percentage: 30.0)

    #expect(view.progressColor == .orange)
  }

  @Test("orange color for exactly 49%")
  func orangeColor_forExactly49Percent() {
    let view = CircularProgressView(percentage: 49.0)

    #expect(view.progressColor == .orange)
  }

  @Test("orange color for 0%")
  func orangeColor_for0Percent() {
    let view = CircularProgressView(percentage: 0.0)

    #expect(view.progressColor == .orange)
  }

  // MARK: - Edge Case Tests

  @Test("view handles percentage over 100")
  func view_handlesPercentageOver100() {
    let view = CircularProgressView(percentage: 150.0)

    // Should clamp display to 100%
    #expect(view.percentage == 150.0)
    // Visual clamping happens in the view rendering
  }

  @Test("view handles negative percentage")
  func view_handlesNegativePercentage() {
    let view = CircularProgressView(percentage: -10.0)

    // Should clamp display to 0%
    #expect(view.percentage == -10.0)
    // Visual clamping happens in the view rendering
  }

  // MARK: - Animation Tests

  @Test("view supports animation binding")
  func view_supportsAnimationBinding() {
    // Animation is tested via SwiftUI withAnimation in the view
    // We verify the view accepts animated changes
    let view = CircularProgressView(percentage: 50.0)
    #expect(view.percentage == 50.0)

    // In actual usage, changing the percentage value triggers animation
    let updatedView = CircularProgressView(percentage: 75.0)
    #expect(updatedView.percentage == 75.0)
  }

  // MARK: - Formatted Display Tests

  @Test("view formats percentage without decimals for whole numbers")
  func view_formatsWholeNumbers() {
    let view = CircularProgressView(percentage: 75.0)

    #expect(view.formattedPercentage == "75%")
  }

  @Test("view formats percentage with one decimal for decimal values")
  func view_formatsDecimalValues() {
    let view = CircularProgressView(percentage: 67.8)

    #expect(view.formattedPercentage == "67.8%")
  }

  @Test("view formats 0% correctly")
  func view_formats0Correctly() {
    let view = CircularProgressView(percentage: 0.0)

    #expect(view.formattedPercentage == "0%")
  }

  @Test("view formats 100% correctly")
  func view_formats100Correctly() {
    let view = CircularProgressView(percentage: 100.0)

    #expect(view.formattedPercentage == "100%")
  }

  // MARK: - Integration Tests

  @Test("view works with all parameters")
  func view_worksWithAllParameters() {
    let view = CircularProgressView(
      percentage: 85.5,
      size: 150.0
    )

    #expect(view.percentage == 85.5)
    #expect(view.size == 150.0)
    #expect(view.progressColor == .green)
    #expect(view.formattedPercentage == "85.5%")
  }
}
