import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

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

  // MARK: - Tint Tests

  // Color is no longer derived from the value (the green/yellow/orange
  // "performance grading" was removed per #281); the tint is a fixed input.

  @Test("view uses the neutral interactive accent tint by default")
  func view_usesDefaultTint() {
    let view = CircularProgressView(percentage: 85.0)

    #expect(view.tint == WLColorTokens.interactiveAccent)
  }

  @Test("default tint does not depend on the percentage value")
  func view_defaultTintIsValueIndependent() {
    let low = CircularProgressView(percentage: 10.0)
    let high = CircularProgressView(percentage: 95.0)

    #expect(low.tint == high.tint)
  }

  @Test("view preserves a custom tint")
  func view_preservesCustomTint() {
    let view = CircularProgressView(percentage: 50.0, tint: WLColorTokens.teal)

    #expect(view.tint == WLColorTokens.teal)
  }

  // MARK: - Edge Case Tests

  @Test("view stores raw over-100 percentage but clamps the label to 100%")
  func view_handlesPercentageOver100() {
    let view = CircularProgressView(percentage: 150.0)

    #expect(view.percentage == 150.0)
    #expect(view.formattedPercentage == "100%")
  }

  @Test("view stores raw negative percentage but clamps the label to 0%")
  func view_handlesNegativePercentage() {
    let view = CircularProgressView(percentage: -10.0)

    #expect(view.percentage == -10.0)
    #expect(view.formattedPercentage == "0%")
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
      size: 150.0,
      tint: WLColorTokens.purple
    )

    #expect(view.percentage == 85.5)
    #expect(view.size == 150.0)
    #expect(view.tint == WLColorTokens.purple)
    #expect(view.formattedPercentage == "85.5%")
  }
}
