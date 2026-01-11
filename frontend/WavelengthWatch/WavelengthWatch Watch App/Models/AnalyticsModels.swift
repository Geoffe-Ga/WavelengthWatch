import Foundation

/// Response model for /api/v1/analytics/overview endpoint
struct AnalyticsOverview: Codable, Equatable {
  let totalEntries: Int
  let currentStreak: Int
  let longestStreak: Int
  let avgFrequency: Double
  let lastCheckIn: Date?
  let medicinalRatio: Double
  let medicinalTrend: Double
  let dominantLayerId: Int?
  let dominantPhaseId: Int?
  let uniqueEmotions: Int
  let strategiesUsed: Int
  let secondaryEmotionsPct: Double

  enum CodingKeys: String, CodingKey {
    case totalEntries = "total_entries"
    case currentStreak = "current_streak"
    case longestStreak = "longest_streak"
    case avgFrequency = "avg_frequency"
    case lastCheckIn = "last_check_in"
    case medicinalRatio = "medicinal_ratio"
    case medicinalTrend = "medicinal_trend"
    case dominantLayerId = "dominant_layer_id"
    case dominantPhaseId = "dominant_phase_id"
    case uniqueEmotions = "unique_emotions"
    case strategiesUsed = "strategies_used"
    case secondaryEmotionsPct = "secondary_emotions_pct"
  }
}

// MARK: - Emotional Landscape Models

/// Layer distribution item for emotional landscape analytics
struct LayerDistributionItem: Codable, Equatable {
  let layerId: Int
  let count: Int
  let percentage: Double

  enum CodingKeys: String, CodingKey {
    case layerId = "layer_id"
    case count
    case percentage
  }
}

/// Phase distribution item for emotional landscape analytics
struct PhaseDistributionItem: Codable, Equatable {
  let phaseId: Int
  let count: Int
  let percentage: Double

  enum CodingKeys: String, CodingKey {
    case phaseId = "phase_id"
    case count
    case percentage
  }
}

/// Top emotion item for emotional landscape analytics
struct TopEmotionItem: Codable, Equatable {
  let curriculumId: Int
  let expression: String
  let layerId: Int
  let phaseId: Int
  let dosage: String
  let count: Int

  enum CodingKeys: String, CodingKey {
    case curriculumId = "curriculum_id"
    case expression
    case layerId = "layer_id"
    case phaseId = "phase_id"
    case dosage
    case count
  }
}

/// Response model for /api/v1/analytics/emotional-landscape endpoint
struct EmotionalLandscape: Codable, Equatable {
  let layerDistribution: [LayerDistributionItem]
  let phaseDistribution: [PhaseDistributionItem]
  let topEmotions: [TopEmotionItem]

  enum CodingKeys: String, CodingKey {
    case layerDistribution = "layer_distribution"
    case phaseDistribution = "phase_distribution"
    case topEmotions = "top_emotions"
  }
}

// MARK: - Self-Care Analytics Models

/// Top strategy item for self-care analytics
struct TopStrategyItem: Codable, Equatable {
  let strategyId: Int
  let strategy: String
  let count: Int
  let percentage: Double

  enum CodingKeys: String, CodingKey {
    case strategyId = "strategy_id"
    case strategy
    case count
    case percentage
  }
}

/// Response model for /api/v1/analytics/self-care endpoint
struct SelfCareAnalytics: Codable, Equatable {
  let topStrategies: [TopStrategyItem]
  let diversityScore: Double
  let totalStrategyEntries: Int

  enum CodingKeys: String, CodingKey {
    case topStrategies = "top_strategies"
    case diversityScore = "diversity_score"
    case totalStrategyEntries = "total_strategy_entries"
  }
}

// MARK: - Temporal Patterns Models

/// Hourly distribution item for temporal analytics
struct HourlyDistributionItem: Codable, Equatable {
  let hour: Int
  let count: Int
}

/// Response model for /api/v1/analytics/temporal endpoint
struct TemporalPatterns: Codable, Equatable {
  let hourlyDistribution: [HourlyDistributionItem]
  let consistencyScore: Double

  enum CodingKeys: String, CodingKey {
    case hourlyDistribution = "hourly_distribution"
    case consistencyScore = "consistency_score"
  }
}

// MARK: - Growth Indicators Models

/// Response model for /api/v1/analytics/growth endpoint
struct GrowthIndicators: Codable, Equatable {
  let medicinalTrend: Double
  let layerDiversity: Int
  let phaseCoverage: Int

  enum CodingKeys: String, CodingKey {
    case medicinalTrend = "medicinal_trend"
    case layerDiversity = "layer_diversity"
    case phaseCoverage = "phase_coverage"
  }
}
