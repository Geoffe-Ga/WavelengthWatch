/// Navigation destinations for programmatic navigation control.
/// Using value-based navigation allows NavigationPath to track pushed views.
enum DetailDestination: Hashable {
  case curriculum(layer: CatalogLayerModel, phase: CatalogPhaseModel, colorName: String)
  case strategy(phase: CatalogPhaseModel, colorName: String)
}
