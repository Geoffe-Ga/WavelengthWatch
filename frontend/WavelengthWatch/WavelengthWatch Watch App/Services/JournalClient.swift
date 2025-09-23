import Foundation

struct JournalResponseModel: Codable, Equatable {
  let id: Int
  let curriculumID: Int
  let secondaryCurriculumID: Int?
  let strategyID: Int?

  enum CodingKeys: String, CodingKey {
    case id
    case curriculumID = "curriculum_id"
    case secondaryCurriculumID = "secondary_curriculum_id"
    case strategyID = "strategy_id"
  }
}

struct JournalPayload: Codable {
  let createdAt: Date
  let userID: Int
  let curriculumID: Int
  let secondaryCurriculumID: Int?
  let strategyID: Int?

  enum CodingKeys: String, CodingKey {
    case createdAt = "created_at"
    case userID = "user_id"
    case curriculumID = "curriculum_id"
    case secondaryCurriculumID = "secondary_curriculum_id"
    case strategyID = "strategy_id"
  }
}

protocol JournalClientProtocol {
  @discardableResult
  func submit(
    curriculumID: Int,
    secondaryCurriculumID: Int?,
    strategyID: Int?
  ) async throws -> JournalResponseModel
}

final class JournalClient: JournalClientProtocol {
  private let apiClient: APIClientProtocol
  private let dateProvider: () -> Date
  private let userDefaults: UserDefaults
  private let userDefaultsKey = "com.wavelengthwatch.userIdentifier"

  init(apiClient: APIClientProtocol, dateProvider: @escaping () -> Date = Date.init, userDefaults: UserDefaults = .standard) {
    self.apiClient = apiClient
    self.dateProvider = dateProvider
    self.userDefaults = userDefaults
  }

  private func storedUserIdentifier() -> String {
    if let identifier = userDefaults.string(forKey: userDefaultsKey) {
      return identifier
    }
    let identifier = UUID().uuidString
    userDefaults.set(identifier, forKey: userDefaultsKey)
    return identifier
  }

  private func numericUserIdentifier() -> Int {
    let identifier = storedUserIdentifier().replacingOccurrences(of: "-", with: "")
    let prefix = identifier.prefix(12)
    return Int(prefix, radix: 16) ?? 0
  }

  @discardableResult
  func submit(
    curriculumID: Int,
    secondaryCurriculumID: Int?,
    strategyID: Int?
  ) async throws -> JournalResponseModel {
    let payload = JournalPayload(
      createdAt: dateProvider(),
      userID: numericUserIdentifier(),
      curriculumID: curriculumID,
      secondaryCurriculumID: secondaryCurriculumID,
      strategyID: strategyID
    )
    return try await apiClient.post(APIPath.journal, body: payload)
  }
}
