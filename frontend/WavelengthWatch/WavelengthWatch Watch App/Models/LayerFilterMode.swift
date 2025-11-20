import Foundation

/// Defines filtering modes for layer visibility in the emotion logging flow.
///
/// The app displays layers in three distinct contexts:
/// - **Browse mode**: All layers (0-10) are visible for free exploration
/// - **Emotion selection**: Only emotion layers (1-10) visible, strategies layer hidden
/// - **Strategy selection**: Only strategies layer (0) visible, emotion layers hidden
enum LayerFilterMode: Equatable {
  /// Browse mode - shows all layers (0-10)
  case all

  /// Emotion selection mode - shows only emotion layers (1-10), hides strategies (layer 0)
  case emotionsOnly

  /// Strategy selection mode - shows only strategies layer (0), hides emotion layers (1-10)
  case strategiesOnly

  /// Filters a collection of layers based on the current mode.
  ///
  /// - Parameter layers: The full collection of catalog layers to filter
  /// - Returns: A filtered array containing only layers matching this mode's criteria
  func filter(_ layers: [CatalogLayerModel]) -> [CatalogLayerModel] {
    switch self {
    case .all:
      layers
    case .emotionsOnly:
      layers.filter { $0.id >= 1 }
    case .strategiesOnly:
      layers.filter { $0.id == 0 }
    }
  }
}
