import SwiftUI

/// A reusable circular progress indicator with a centered percentage label.
///
/// The ring renders in a single `tint` color (default
/// `WLColorTokens.interactiveAccent`) and never derives its color from the
/// value — progress is shown descriptively, not graded good/bad. The previous
/// green/yellow/orange "performance grading" was removed per #281.
///
/// The track holds more contrast under Reduce Transparency so the unfilled
/// portion stays legible, and the fill animation is suppressed under Reduce
/// Motion via `wlAnimation`.
///
/// ## Usage
/// ```swift
/// CircularProgressView(percentage: 75.0)                       // default tint + size
/// CircularProgressView(percentage: 60.0, size: 120.0)          // custom size
/// CircularProgressView(percentage: 40.0, tint: WLColorTokens.teal)
/// ```
struct CircularProgressView: View {
  /// The percentage value to display (0–100).
  let percentage: Double

  /// The diameter of the ring in points.
  let size: CGFloat

  /// The ring's fill color. Neutral by default; callers may pass a section or
  /// layer accent, but the component never derives color from the value.
  let tint: Color

  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  /// Creates a new circular progress view.
  /// - Parameters:
  ///   - percentage: The percentage value to display (0–100).
  ///   - size: The diameter of the view in points (default: 100).
  ///   - tint: The ring fill color (default: `WLColorTokens.interactiveAccent`).
  init(
    percentage: Double,
    size: CGFloat = 100.0,
    tint: Color = WLColorTokens.interactiveAccent
  ) {
    self.percentage = percentage
    self.size = size
    self.tint = tint
  }

  var body: some View {
    ZStack {
      // Track circle
      Circle()
        .stroke(trackColor, lineWidth: strokeWidth)
        .frame(width: size, height: size)

      // Progress circle
      Circle()
        .trim(from: 0, to: clampedProgress)
        .stroke(
          tint,
          style: StrokeStyle(
            lineWidth: strokeWidth,
            lineCap: .round
          )
        )
        .frame(width: size, height: size)
        .rotationEffect(.degrees(-90)) // Start from top
        .wlAnimation(.easeInOut(duration: 0.5), value: percentage)

      // Percentage text
      Text(formattedPercentage)
        .font(percentageFontSize)
        .fontWeight(.bold)
        .foregroundColor(WLColorTokens.primaryText)
    }
  }

  // MARK: - Computed Properties

  /// Returns the formatted percentage string, clamped to 0–100 so the label
  /// can't disagree with the ring fill (which clamps via `clampedProgress`).
  /// `internal` for test access.
  var formattedPercentage: String {
    let clamped = min(max(percentage, 0), 100)
    // Show one decimal place if needed, otherwise show whole number
    if clamped.truncatingRemainder(dividingBy: 1) == 0 {
      return "\(Int(clamped))%"
    } else {
      return String(format: "%.1f%%", clamped)
    }
  }

  /// Track (unfilled) ring color. Holds more contrast under Reduce
  /// Transparency so the ring stays visible without relying on faint
  /// translucency.
  private var trackColor: Color {
    Color.secondary.opacity(reduceTransparency ? 0.4 : 0.2)
  }

  /// Clamps the progress value between 0 and 1 for the trim modifier.
  private var clampedProgress: CGFloat {
    min(max(percentage / 100.0, 0.0), 1.0)
  }

  /// Calculates the stroke width based on size (10% of the diameter).
  private var strokeWidth: CGFloat {
    size * 0.1
  }

  /// Adapts the centered label font to the ring size.
  private var percentageFontSize: Font {
    if size < 80 {
      .caption
    } else if size < 120 {
      .body
    } else {
      .title3
    }
  }
}

// MARK: - Previews

#Preview("Default tint") {
  VStack(spacing: 20) {
    CircularProgressView(percentage: 85.0)
    CircularProgressView(percentage: 35.0)
  }
  .padding()
}

#Preview("Custom tints") {
  VStack(spacing: 20) {
    CircularProgressView(percentage: 70.0, tint: WLColorTokens.teal)
    CircularProgressView(percentage: 45.0, tint: WLColorTokens.purple)
  }
  .padding()
}

#Preview("Sizes") {
  VStack(spacing: 20) {
    CircularProgressView(percentage: 75.0, size: 150.0)
    CircularProgressView(percentage: 45.0, size: 60.0)
  }
  .padding()
}

#Preview("Edge cases") {
  VStack(spacing: 20) {
    CircularProgressView(percentage: 0.0)
    CircularProgressView(percentage: 100.0)
  }
  .padding()
}

#Preview("Animation Demo") {
  AnimatedProgressPreview()
}

/// Helper view for animation preview
private struct AnimatedProgressPreview: View {
  @State private var progress: Double = 0

  var body: some View {
    VStack(spacing: 20) {
      CircularProgressView(percentage: progress)

      Button("Animate") {
        withAnimation {
          progress = Double.random(in: 0 ... 100)
        }
      }
    }
    .padding()
  }
}
