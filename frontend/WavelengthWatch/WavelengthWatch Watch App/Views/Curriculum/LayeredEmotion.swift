import SwiftUI

/// Helper struct for displaying emotions with their source layer info (used in Clear Light view)
struct LayeredEmotion: Identifiable, Hashable {
  /// Unique identifier combining layer ID and entry ID to handle potential duplicates
  let id: String
  let entry: CatalogCurriculumEntryModel
  let layerTitle: String
  let layerColor: String

  init(layerId: Int, entry: CatalogCurriculumEntryModel, layerTitle: String, layerColor: String) {
    // Composite key ensures uniqueness even if same entry appears in multiple contexts
    self.id = "\(layerId)-\(entry.id)"
    self.entry = entry
    self.layerTitle = layerTitle
    self.layerColor = layerColor
  }

  var sourceColor: Color {
    Color(stage: layerColor)
  }
}
