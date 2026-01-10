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
