import Foundation

struct CatalogStrategyModel: Codable, Identifiable, Equatable, Hashable {
  let id: Int
  let strategy: String
  let color: String
}

enum CatalogDosage: String, Codable, Hashable {
  case medicinal = "Medicinal"
  case toxic = "Toxic"
}

struct CatalogCurriculumEntryModel: Codable, Identifiable, Equatable, Hashable {
  let id: Int
  let dosage: CatalogDosage
  let expression: String
}

struct CatalogPhaseModel: Codable, Identifiable, Equatable, Hashable {
  let id: Int
  let name: String
  let medicinal: [CatalogCurriculumEntryModel]
  let toxic: [CatalogCurriculumEntryModel]
  let strategies: [CatalogStrategyModel]
}

struct CatalogLayerModel: Codable, Identifiable, Equatable, Hashable {
  let id: Int
  let color: String
  let title: String
  let subtitle: String
  let phases: [CatalogPhaseModel]
}

struct CatalogResponseModel: Codable, Equatable {
  let phaseOrder: [String]
  let layers: [CatalogLayerModel]

  enum CodingKeys: String, CodingKey {
    case phaseOrder = "phase_order"
    case layers
  }
}

struct CatalogCacheEnvelope: Codable {
  let fetchedAt: Date
  let catalog: CatalogResponseModel
}
