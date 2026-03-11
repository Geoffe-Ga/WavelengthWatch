import SwiftUI

struct LayerCardView: View {
  let layer: CatalogLayerModel
  let phaseCount: Int
  @Binding var selection: Int
  let layerIndex: Int
  let selectedLayerIndex: Int
  let geometry: GeometryProxy
  let screenWidth: CGFloat // Stable width from parent GeometryReader
  @EnvironmentObject private var viewModel: ContentViewModel

  private var transformEffect: (scale: CGFloat, rotation: Double, offset: CGFloat, opacity: Double) {
    let distance = layerIndex - selectedLayerIndex

    switch distance {
    case 0:
      return (scale: 1.0, rotation: 0, offset: 0, opacity: 1.0)
    case 1:
      return (scale: 0.95, rotation: -5, offset: 15, opacity: 0.3)
    case -1:
      return (scale: 0.95, rotation: 5, offset: -15, opacity: 0.3)
    default:
      return (scale: 0.85, rotation: 0, offset: 0, opacity: 0.0)
    }
  }

  var body: some View {
    LayerView(
      layer: layer,
      phaseCount: phaseCount,
      selection: $selection,
      screenWidth: screenWidth
    )
    .frame(width: geometry.size.width, height: geometry.size.height)
    .scaleEffect(transformEffect.scale)
    .rotation3DEffect(
      .degrees(transformEffect.rotation),
      axis: (x: 1, y: 0, z: 0),
      perspective: 0.8
    )
    .offset(y: transformEffect.offset)
    .opacity(transformEffect.opacity)
    .zIndex(layerIndex == selectedLayerIndex ? 10 : Double(10 - abs(layerIndex - selectedLayerIndex)))
    .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: selectedLayerIndex)
  }
}
