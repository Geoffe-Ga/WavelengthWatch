import SwiftUI

/// A loading skeleton view for analytics components while data is being fetched
struct AnalyticsLoadingView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header skeleton
      RoundedRectangle(cornerRadius: 4)
        .fill(Color.secondary.opacity(0.2))
        .frame(width: 120, height: 16)
        .shimmering()

      // Content skeleton
      VStack(alignment: .leading, spacing: 8) {
        ForEach(0 ..< 3, id: \.self) { _ in
          HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
              .fill(Color.secondary.opacity(0.15))
              .frame(width: 50, height: 20)
              .shimmering()

            RoundedRectangle(cornerRadius: 3)
              .fill(Color.secondary.opacity(0.1))
              .frame(height: 20)
              .shimmering()
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Loading analytics data")
  }
}

/// A view modifier that adds a shimmer animation effect to loading skeletons.
///
/// The shimmer is a perpetual translucent sweep, so it is suppressed under
/// either Reduce Motion (no perpetual animation) or Reduce Transparency (no
/// decorative translucent overlay) — leaving a static skeleton in those modes.
struct ShimmerModifier: ViewModifier {
  @State private var phase: CGFloat = 0
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  func body(content: Content) -> some View {
    if reduceMotion || reduceTransparency {
      content
    } else {
      content
        .overlay(
          GeometryReader { geometry in
            LinearGradient(
              gradient: Gradient(colors: [
                Color.clear,
                Color.white.opacity(0.3),
                Color.clear,
              ]),
              startPoint: .leading,
              endPoint: .trailing
            )
            .frame(width: geometry.size.width * 2)
            .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
          }
          .mask(content)
        )
        .onAppear {
          withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            phase = 1
          }
        }
    }
  }
}

extension View {
  /// Adds a shimmer loading animation effect
  func shimmering() -> some View {
    modifier(ShimmerModifier())
  }
}

// MARK: - Previews

#Preview("Loading State") {
  AnalyticsLoadingView()
    .padding()
}
