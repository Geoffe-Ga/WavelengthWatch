import Foundation

protocol AnalyticsServiceProtocol {
  func getOverview(userId: Int) async throws -> AnalyticsOverview
  func getEmotionalLandscape(userId: Int) async throws -> EmotionalLandscape
  func getSelfCare(userId: Int, limit: Int) async throws -> SelfCareAnalytics
  func getTemporalPatterns(userId: Int, startDate: Date, endDate: Date) async throws -> TemporalPatterns
  func getGrowthIndicators(userId: Int, startDate: Date, endDate: Date) async throws -> GrowthIndicators
}

final class AnalyticsService: AnalyticsServiceProtocol {
  private let apiClient: APIClientProtocol

  init(apiClient: APIClientProtocol) {
    self.apiClient = apiClient
  }

  func getOverview(userId: Int) async throws -> AnalyticsOverview {
    let path = "\(APIPath.analyticsOverview)?user_id=\(userId)"
    return try await apiClient.get(path)
  }

  func getEmotionalLandscape(userId: Int) async throws -> EmotionalLandscape {
    let path = "\(APIPath.analyticsEmotionalLandscape)?user_id=\(userId)"
    return try await apiClient.get(path)
  }

  func getSelfCare(userId: Int, limit: Int) async throws -> SelfCareAnalytics {
    let path = "\(APIPath.analyticsSelfCare)?user_id=\(userId)&limit=\(limit)"
    return try await apiClient.get(path)
  }

  func getTemporalPatterns(
    userId: Int,
    startDate: Date,
    endDate: Date
  ) async throws -> TemporalPatterns {
    let formatter = ISO8601DateFormatter()
    let startStr = formatter.string(from: startDate)
    let endStr = formatter.string(from: endDate)
    let path = "\(APIPath.analyticsTemporal)?user_id=\(userId)&start_date=\(startStr)&end_date=\(endStr)"
    return try await apiClient.get(path)
  }

  func getGrowthIndicators(
    userId: Int,
    startDate: Date,
    endDate: Date
  ) async throws -> GrowthIndicators {
    let formatter = ISO8601DateFormatter()
    let startStr = formatter.string(from: startDate)
    let endStr = formatter.string(from: endDate)
    let path = "\(APIPath.analyticsGrowth)?user_id=\(userId)&start_date=\(startStr)&end_date=\(endStr)"
    return try await apiClient.get(path)
  }
}
