import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

private struct SampleData {
  static let catalog: CatalogResponseModel = {
    let medicinal = CatalogCurriculumEntryModel(id: 1, dosage: .medicinal, expression: "Commitment")
    let toxic = CatalogCurriculumEntryModel(id: 2, dosage: .toxic, expression: "Overcommitment")
    let strategy = CatalogStrategyModel(id: 3, strategy: "Cold Shower")
    let phase = CatalogPhaseModel(id: 1, name: "Rising", medicinal: [medicinal], toxic: [toxic], strategies: [strategy])
    let layer = CatalogLayerModel(id: 1, color: "Beige", title: "SELF-CARE", subtitle: "(For Surfing)", phases: [phase])
    return CatalogResponseModel(phaseOrder: ["Rising"], layers: [layer])
  }()
}

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

final class CatalogCacheStub: CatalogCachePersisting {
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

struct CatalogRepositoryTests {
  private func makeRepository(
    remote: CatalogRemoteStub,
    cache: CatalogCacheStub,
    now: @escaping () -> Date,
    ttl: TimeInterval = 60 * 60 * 24
  ) -> CatalogRepository {
    CatalogRepository(
      remote: remote,
      cache: cache,
      dateProvider: now,
      cacheTTL: ttl
    )
  }

  @Test func returnsCachedCatalogWhenFresh() async throws {
    let remote = CatalogRemoteStub(response: SampleData.catalog)
    let cache = CatalogCacheStub()
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let envelope = CatalogCacheEnvelope(fetchedAt: Date(timeIntervalSince1970: 1_000), catalog: SampleData.catalog)
    cache.storedData = try encoder.encode(envelope)
    let repository = makeRepository(remote: remote, cache: cache, now: { Date(timeIntervalSince1970: 1_500) })

    #expect(repository.cachedCatalog() == SampleData.catalog)
    let catalog = try await repository.loadCatalog()
    #expect(catalog == SampleData.catalog)
    #expect(remote.fetchCount == 0)
  }

  @Test func refreshesWhenCacheIsStale() async throws {
    let remote = CatalogRemoteStub(response: SampleData.catalog)
    let cache = CatalogCacheStub()
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let staleDate = Date(timeIntervalSince1970: 0)
    let envelope = CatalogCacheEnvelope(fetchedAt: staleDate, catalog: SampleData.catalog)
    cache.storedData = try encoder.encode(envelope)
    let repository = makeRepository(remote: remote, cache: cache, now: { Date(timeIntervalSince1970: 60 * 60 * 24 + 10) })

    let catalog = try await repository.loadCatalog()
    #expect(catalog == SampleData.catalog)
    #expect(remote.fetchCount == 1)
  }

  @Test func invalidatesCorruptCache() async throws {
    let remote = CatalogRemoteStub(response: SampleData.catalog)
    let cache = CatalogCacheStub()
    cache.storedData = Data("invalid".utf8)
    let repository = makeRepository(remote: remote, cache: cache, now: { Date() })

    let catalog = try await repository.loadCatalog()
    #expect(catalog == SampleData.catalog)
    #expect(remote.fetchCount == 1)
    #expect(cache.storedData != nil)
  }
}

final class APIClientSpy: APIClientProtocol {
  var lastPath: String?
  var lastBody: Data?
  var response = JournalResponseModel(id: 10, curriculumID: 5, secondaryCurriculumID: 7, strategyID: 9)
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  init() {
    encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
  }

  func get<T>(_ path: String) async throws -> T where T: Decodable {
    throw NSError(domain: "unimplemented", code: 1)
  }

  func post<Body, Response>(_ path: String, body: Body) async throws -> Response where Body: Encodable, Response: Decodable {
    lastPath = path
    lastBody = try encoder.encode(body)
    let data = try encoder.encode(response)
    return try decoder.decode(Response.self, from: data)
  }
}

struct JournalClientTests {
  @Test func encodesPayloadWithStableUserIdentifier() async throws {
    let spy = APIClientSpy()
    let defaults = UserDefaults(suiteName: "JournalClientTests")!
    defaults.removePersistentDomain(forName: "JournalClientTests")
    defaults.set("12345678-1234-1234-1234-1234567890ab", forKey: "com.wavelengthwatch.userIdentifier")
    let date = Date(timeIntervalSince1970: 1_000)
    let client = JournalClient(apiClient: spy, dateProvider: { date }, userDefaults: defaults)

    _ = try await client.submit(curriculumID: 5, secondaryCurriculumID: 7, strategyID: 9)

    #expect(spy.lastPath == "/journal")
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let payload = try decoder.decode(JournalPayload.self, from: spy.lastBody ?? Data())
    #expect(payload.curriculumID == 5)
    #expect(payload.secondaryCurriculumID == 7)
    #expect(payload.strategyID == 9)
    #expect(payload.createdAt == date)
    let expected = Int("123456781234", radix: 16) ?? 0
    #expect(payload.userID == expected)
  }
}

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
  var shouldFail = false

  func submit(
    curriculumID: Int,
    secondaryCurriculumID: Int?,
    strategyID: Int?
  ) async throws -> JournalResponseModel {
    submissions.append((curriculumID, secondaryCurriculumID, strategyID))
    if shouldFail {
      throw ErrorStub()
    }
    return JournalResponseModel(id: 1, curriculumID: curriculumID, secondaryCurriculumID: secondaryCurriculumID, strategyID: strategyID)
  }
}

struct ContentViewModelTests {
  @MainActor
  @Test func loadsCatalogSuccessfully() async throws {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.loadCatalog()

    #expect(!viewModel.layers.isEmpty)
    #expect(viewModel.loadErrorMessage == nil)
    #expect(viewModel.isLoading == false)
  }

  @MainActor
  @Test func surfacesErrorWhenLoadingFails() async {
    enum TestError: Error { case failure }
    let repository = CatalogRepositoryMock(result: .failure(TestError.failure))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.loadCatalog()

    #expect(viewModel.layers.isEmpty)
    #expect(viewModel.loadErrorMessage != nil)
  }

  @MainActor
  @Test func retriesAfterFailure() async {
    enum TestError: Error { case failure }
    let repository = CatalogRepositoryMock(result: .failure(TestError.failure))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.loadCatalog()
    #expect(viewModel.layers.isEmpty)

    repository.result = .success(SampleData.catalog)
    await viewModel.retry()

    #expect(!viewModel.layers.isEmpty)
    #expect(viewModel.loadErrorMessage == nil)
  }

  @MainActor
  @Test func reportsJournalOutcome() async {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.journal(curriculumID: 1)
    switch viewModel.journalFeedback?.kind {
    case .success?: #expect(true)
    default: #expect(Bool(false))
    }

    journal.shouldFail = true
    await viewModel.journal(curriculumID: 1)
    switch viewModel.journalFeedback?.kind {
    case let .failure(message)?:
      #expect(message.contains("try again"))
    default: #expect(Bool(false))
    }
  }
}

struct PhaseNavigatorTests {
  @Test func wrapsFromFirstToLast() {
    let adjusted = PhaseNavigator.adjustedSelection(0, phaseCount: 6)
    #expect(adjusted == 6)
  }

  @Test func wrapsFromLastToFirst() {
    let adjusted = PhaseNavigator.adjustedSelection(7, phaseCount: 6)
    #expect(adjusted == 1)
  }

  @Test func normalizesSelection() {
    let index = PhaseNavigator.normalizedIndex(1, phaseCount: 6)
    #expect(index == 0)
    let last = PhaseNavigator.normalizedIndex(6, phaseCount: 6)
    #expect(last == 5)
  }
}
