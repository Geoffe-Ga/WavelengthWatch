import Foundation

protocol AnalyticsServiceProtocol {
  func getOverview(userId: Int) async throws -> AnalyticsOverview
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
}
