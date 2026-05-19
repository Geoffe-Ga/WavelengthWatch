import SwiftUI

/// Auto-fading right-edge indicator showing the current layer's position
/// in the stack. Each layer is a small capsule; the selected one is
/// larger, brighter, and shadowed in the layer's color. Distant layers
/// scale down and fade out so the indicator stays compact on small
/// screen sizes.
struct LayerSideIndicator: View {
  let layers: [CatalogLayerModel]
  let selection: Int
  let size: CGSize

  var body: some View {
    VStack {
      Spacer()
      ZStack(alignment: .top) {
        Capsule()
          .fill(Color.white.opacity(0.1))
          .frame(width: 4, height: size.height * 0.5)

        VStack(spacing: 2) {
          ForEach(layers.indices, id: \.self) { index in
            indicatorCapsule(at: index)
          }
        }
      }
      // Offset (not padding) so opacity changes don't shift layout.
      .offset(x: -6)
      Spacer()
    }
  }

  private func indicatorCapsule(at index: Int) -> some View {
    let layer = layers[index]
    let isSelected = index == selection
    let distance = abs(index - selection)

    return Capsule()
      .fill(fill(for: layer, selected: isSelected))
      .frame(
        width: isSelected ? 8 : 4,
        height: isSelected ? 16 : 8
      )
      .overlay(
        Capsule()
          .stroke(
            isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.1),
            lineWidth: 0.5
          )
      )
      .shadow(
        color: isSelected ? Color(stage: layer.color) : Color.clear,
        radius: isSelected ? 3 : 0
      )
      .scaleEffect(distance > 2 ? 0.6 : 1.0)
      .opacity(distance > 3 ? 0 : 1)
      .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: selection)
  }

  private func fill(for layer: CatalogLayerModel, selected: Bool) -> LinearGradient {
    let base = Color(stage: layer.color)
    if selected {
      return LinearGradient(
        colors: [base, base.opacity(0.7)],
        startPoint: .top,
        endPoint: .bottom
      )
    }
    return LinearGradient(
      colors: [base.opacity(0.3), base.opacity(0.1)],
      startPoint: .top,
      endPoint: .bottom
    )
  }
}
