/// Navigation destinations for programmatic navigation control.
/// Using value-based navigation allows NavigationPath to track pushed views.
enum DetailDestination: Hashable {
  case curriculum(layer: CatalogLayerModel, phase: CatalogPhaseModel, colorName: String)
  case strategy(phase: CatalogPhaseModel, colorName: String)

  /// The destination for a layer/phase pair: the strategies layer (id 0)
  /// routes to `.strategy`, every other layer to `.curriculum`. Centralized so
  /// the single hoisted navigation chevron (see `LayerScrollView`) and any
  /// other caller route identically.
  static func forPhase(in layer: CatalogLayerModel, phase: CatalogPhaseModel) -> DetailDestination {
    if layer.id == 0 {
      .strategy(phase: phase, colorName: layer.color)
    } else {
      .curriculum(layer: layer, phase: phase, colorName: layer.color)
    }
  }
}
