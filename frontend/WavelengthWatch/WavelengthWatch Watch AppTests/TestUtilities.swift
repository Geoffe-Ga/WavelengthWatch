import Foundation
import SwiftUI
import Testing
import UserNotifications
@testable import WavelengthWatch_Watch_App

// Shared test mocks and utilities used across multiple test files

// MARK: - Bundle Mock

/// Mock Bundle for testing AppConfiguration
/// Note: This mock is only used synchronously within single-threaded tests,
/// so mutable state is safe. Not marked Sendable to avoid false safety claims.
final class MockBundle: BundleProtocol {
  var infoPlistValues: [String: Any] = [:]
  var plistPaths: [String: String] = [:]

  func object(forInfoDictionaryKey key: String) -> Any? {
    infoPlistValues[key]
  }

  func path(forResource name: String?, ofType ext: String?) -> String? {
    guard let name else { return nil }
    return plistPaths[name]
  }
}

// MARK: - Catalog Cache Mock

/// In-memory cache implementation for tests - avoids file I/O overhead
final class InMemoryCatalogCacheMock: CatalogCachePersisting {
  var storedData: Data?
  var removeCount = 0

  func loadCatalogData() throws -> Data? {
    storedData
  }

  func writeCatalogData(_ data: Data) throws {
    storedData = data
  }

  func removeCatalogData() throws {
    storedData = nil
    removeCount += 1
  }
}

// MARK: - Notification Center Mock

/// Mock implementation of UNUserNotificationCenter for testing
/// Eliminates system IPC overhead (~100-500ms per test) and prevents state pollution
/// between test runs. All notification tests MUST use this mock instead of the real
/// notification center to ensure fast, isolated, deterministic tests.
final class MockNotificationCenter: NotificationCenterProtocol {
  var requestedPermissions: UNAuthorizationOptions?
  var permissionResult: Bool = true
  var addedRequests: [UNNotificationRequest] = []
  var removedAllPending = false
  var categoriesSet: Set<UNNotificationCategory> = []

  func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
    requestedPermissions = options
    return permissionResult
  }

  func add(_ request: UNNotificationRequest) async throws {
    addedRequests.append(request)
  }

  func removeAllPendingNotificationRequests() {
    removedAllPending = true
    addedRequests.removeAll()
  }

  func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
    categoriesSet = categories
  }

  /// Verifies that this mock was actually used (no system calls were made)
  /// Call this in tests to ensure the mock is properly injected
  func assertWasUsed() {
    // If this mock has any recorded interactions, it was successfully used
    let wasUsed = requestedPermissions != nil ||
      !addedRequests.isEmpty ||
      removedAllPending ||
      !categoriesSet.isEmpty
    assert(wasUsed, "MockNotificationCenter was not used - check that it's properly injected")
  }
}

// MARK: - Sample Data

enum SampleData {
  static let catalog: CatalogResponseModel = {
    let medicinal = CatalogCurriculumEntryModel(id: 1, dosage: .medicinal, expression: "Commitment")
    let toxic = CatalogCurriculumEntryModel(id: 2, dosage: .toxic, expression: "Overcommitment")
    let strategy = CatalogStrategyModel(id: 3, strategy: "Cold Shower", color: "Blue")
    let phase = CatalogPhaseModel(id: 1, name: "Rising", medicinal: [medicinal], toxic: [toxic], strategies: [strategy])

    // Mimic production: Layers 0-10 (strategies + all spiral dynamics colors)
    let layers = [
      // Layer 0: Strategies
      CatalogLayerModel(id: 0, color: "Strategies", title: "SELF-CARE", subtitle: "(Strategies)", phases: [phase]),
      // Layers 1-10: Emotion layers (spiral dynamics)
      CatalogLayerModel(id: 1, color: "Beige", title: "BEIGE", subtitle: "(Survival)", phases: [phase]),
      CatalogLayerModel(id: 2, color: "Purple", title: "PURPLE", subtitle: "(Tribal)", phases: [phase]),
      CatalogLayerModel(id: 3, color: "Red", title: "RED", subtitle: "(Power)", phases: [phase]),
      CatalogLayerModel(id: 4, color: "Blue", title: "BLUE", subtitle: "(Order)", phases: [phase]),
      CatalogLayerModel(id: 5, color: "Orange", title: "ORANGE", subtitle: "(Achievement)", phases: [phase]),
      CatalogLayerModel(id: 6, color: "Green", title: "GREEN", subtitle: "(Community)", phases: [phase]),
      CatalogLayerModel(id: 7, color: "Yellow", title: "YELLOW", subtitle: "(Integral)", phases: [phase]),
      CatalogLayerModel(id: 8, color: "Turquoise", title: "TURQUOISE", subtitle: "(Holistic)", phases: [phase]),
      CatalogLayerModel(id: 9, color: "Coral", title: "CORAL", subtitle: "(Transpersonal)", phases: [phase]),
      CatalogLayerModel(id: 10, color: "Teal", title: "TEAL", subtitle: "(Unitive)", phases: [phase]),
    ]

    return CatalogResponseModel(phaseOrder: ["Rising"], layers: layers)
  }()
}

// MARK: - Repository Mocks

final class CatalogRepositoryMock: CatalogRepositoryProtocol {
  var cached: CatalogResponseModel?
  var result: Result<CatalogResponseModel, Error>
  var loadCalls = 0
  var lastForceRefresh: Bool?

  init(cached: CatalogResponseModel? = nil, result: Result<CatalogResponseModel, Error>) {
    self.cached = cached
    self.result = result
  }

  func cachedCatalog() -> CatalogResponseModel? {
    cached
  }

  func loadCatalog(forceRefresh: Bool) async throws -> CatalogResponseModel {
    loadCalls += 1
    lastForceRefresh = forceRefresh
    return try result.get()
  }

  func refreshCatalog() async throws -> CatalogResponseModel {
    try await loadCatalog(forceRefresh: true)
  }
}

final class JournalClientMock: JournalClientProtocol {
  struct ErrorStub: Error {}

  var submissions: [(Int, Int?, Int?)] = []
  var submittedInitiatedBy: InitiatedBy?
  var shouldFail = false

  func submit(
    curriculumID: Int,
    secondaryCurriculumID: Int?,
    strategyID: Int?,
    initiatedBy: InitiatedBy
  ) async throws -> JournalResponseModel {
    submissions.append((curriculumID, secondaryCurriculumID, strategyID))
    submittedInitiatedBy = initiatedBy
    if shouldFail {
      throw ErrorStub()
    }
    return JournalResponseModel(id: 1, curriculumID: curriculumID, secondaryCurriculumID: secondaryCurriculumID, strategyID: strategyID, initiatedBy: initiatedBy)
  }
}

// MARK: - Catalog Remote Stubs

final class CatalogRemoteStub: CatalogRemoteServicing {
  var fetchCount = 0
  var response: CatalogResponseModel

  init(response: CatalogResponseModel) {
    self.response = response
  }

  func fetchCatalog() async throws -> CatalogResponseModel {
    fetchCount += 1
    return response
  }
}

final class FailingRemoteStub: CatalogRemoteServicing {
  let error: Error

  init(error: Error) {
    self.error = error
  }

  func fetchCatalog() async throws -> CatalogResponseModel {
    throw error
  }
}

final class CatalogRepositoryLoggerSpy: CatalogRepositoryLogging {
  private(set) var errors: [Error] = []

  func cacheDecodingFailed(_ error: Error) {
    errors.append(error)
  }
}

// MARK: - API Client Spy

final class APIClientSpy: APIClientProtocol {
  var lastPath: String?
  var lastBody: Data?
  var response = JournalResponseModel(id: 10, curriculumID: 5, secondaryCurriculumID: 7, strategyID: 9, initiatedBy: .self_initiated)
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  init() {
    self.encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    self.decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
  }

  func get<T>(_ path: String) async throws -> T where T: Decodable {
    throw NSError(domain: "unimplemented", code: 1)
  }

  func post<Response>(_ path: String, body: some Encodable) async throws -> Response where Response: Decodable {
    lastPath = path
    lastBody = try encoder.encode(body)
    let data = try encoder.encode(response)
    return try decoder.decode(Response.self, from: data)
  }
}
