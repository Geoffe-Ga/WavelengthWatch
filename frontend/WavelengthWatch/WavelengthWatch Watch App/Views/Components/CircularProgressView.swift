import SwiftUI

/// A reusable circular progress indicator with percentage display and color coding.
///
/// This component displays progress in a circular format with a centered percentage value.
/// The color automatically adjusts based on the percentage value:
/// - Green: >70% (high performance)
/// - Yellow: 50-70% (medium performance)
/// - Orange: <50% (low performance)
///
/// ## Usage
/// ```swift
/// // Default size (100pt)
/// CircularProgressView(percentage: 75.0)
///
/// // Custom size
/// CircularProgressView(percentage: 60.0, size: 120.0)
///
/// // With animation
/// @State private var progress: Double = 0
/// CircularProgressView(percentage: progress)
///   .onAppear {
///     withAnimation {
///       progress = 75.0
///     }
///   }
/// ```
struct CircularProgressView: View {
  /// The percentage value to display (0-100)
  let percentage: Double

  /// The size of the circular progress view in points
  let size: CGFloat

  /// Creates a new circular progress view
  /// - Parameters:
  ///   - percentage: The percentage value to display (0-100)
  ///   - size: The size of the view in points (default: 100)
  init(percentage: Double, size: CGFloat = 100.0) {
    self.percentage = percentage
    self.size = size
  }

  var body: some View {
    ZStack {
      // Background circle
      Circle()
        .stroke(Color.secondary.opacity(0.2), lineWidth: strokeWidth)
        .frame(width: size, height: size)

      // Progress circle
      Circle()
        .trim(from: 0, to: clampedProgress)
        .stroke(
          progressColor,
          style: StrokeStyle(
            lineWidth: strokeWidth,
            lineCap: .round
          )
        )
        .frame(width: size, height: size)
        .rotationEffect(.degrees(-90)) // Start from top
        .animation(.easeInOut(duration: 0.5), value: percentage)

      // Percentage text
      Text(formattedPercentage)
        .font(percentageFontSize)
        .fontWeight(.bold)
        .foregroundColor(progressColor)
    }
  }

  // MARK: - Computed Properties

  /// Returns the progress color based on percentage thresholds
  var progressColor: Color {
    if percentage > 70 {
      .green
    } else if percentage >= 50 {
      .yellow
    } else {
      .orange
    }
  }

  /// Returns the formatted percentage string
  var formattedPercentage: String {
    // Show one decimal place if needed, otherwise show whole number
    if percentage.truncatingRemainder(dividingBy: 1) == 0 {
      "\(Int(percentage))%"
    } else {
      String(format: "%.1f%%", percentage)
    }
  }

  /// Clamps the progress value between 0 and 1 for the trim modifier
  private var clampedProgress: CGFloat {
    min(max(percentage / 100.0, 0.0), 1.0)
  }

  /// Calculates the stroke width based on size
  private var strokeWidth: CGFloat {
    size * 0.1 // 10% of the size
  }

  /// Calculates the font size based on size
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

#Preview("High Progress (85%)") {
  CircularProgressView(percentage: 85.0)
    .padding()
    .previewDisplayName("Green - High")
}

#Preview("Medium Progress (60%)") {
  CircularProgressView(percentage: 60.0)
    .padding()
    .previewDisplayName("Yellow - Medium")
}

#Preview("Low Progress (35%)") {
  CircularProgressView(percentage: 35.0)
    .padding()
    .previewDisplayName("Orange - Low")
}

#Preview("Custom Size (150pt)") {
  CircularProgressView(percentage: 75.0, size: 150.0)
    .padding()
    .previewDisplayName("Large Size")
}

#Preview("Small Size (60pt)") {
  CircularProgressView(percentage: 45.0, size: 60.0)
    .padding()
    .previewDisplayName("Small Size")
}

#Preview("Edge Cases") {
  VStack(spacing: 20) {
    CircularProgressView(percentage: 0.0)
    CircularProgressView(percentage: 100.0)
    CircularProgressView(percentage: 50.0)
    CircularProgressView(percentage: 70.0)
  }
  .padding()
  .previewDisplayName("Edge Cases")
}

#Preview("Animation Demo") {
  AnimatedProgressPreview()
    .previewDisplayName("Animated")
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
