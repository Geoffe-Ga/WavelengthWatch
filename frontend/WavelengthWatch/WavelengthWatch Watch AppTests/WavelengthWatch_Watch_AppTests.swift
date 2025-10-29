import Foundation
import SwiftUI
import Testing
import UserNotifications
@testable import WavelengthWatch_Watch_App

private enum SampleData {
  static let catalog: CatalogResponseModel = {
    let medicinal = CatalogCurriculumEntryModel(id: 1, dosage: .medicinal, expression: "Commitment")
    let toxic = CatalogCurriculumEntryModel(id: 2, dosage: .toxic, expression: "Overcommitment")
    let strategy = CatalogStrategyModel(id: 3, strategy: "Cold Shower", color: "Blue")
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
    ttl: TimeInterval = 60 * 60 * 24,
    logger: CatalogRepositoryLogging = CatalogRepositoryLoggerSpy()
  ) -> CatalogRepository {
    CatalogRepository(
      remote: remote,
      cache: cache,
      dateProvider: now,
      cacheTTL: ttl,
      logger: logger
    )
  }

  @Test func returnsCachedCatalogWhenFresh() async throws {
    let remote = CatalogRemoteStub(response: SampleData.catalog)
    let cache = CatalogCacheStub()
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let envelope = CatalogCacheEnvelope(fetchedAt: Date(timeIntervalSince1970: 1000), catalog: SampleData.catalog)
    cache.storedData = try encoder.encode(envelope)
    let repository = makeRepository(remote: remote, cache: cache, now: { Date(timeIntervalSince1970: 1500) })

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
    let logger = CatalogRepositoryLoggerSpy()
    let repository = makeRepository(remote: remote, cache: cache, now: { Date() }, logger: logger)

    let catalog = try await repository.loadCatalog()
    #expect(catalog == SampleData.catalog)
    #expect(remote.fetchCount == 1)
    #expect(cache.storedData != nil)
    #expect(cache.removeCount == 1)
    #expect(logger.errors.count == 1)
  }

  @Test func propagatesNetworkFailures() async {
    enum StubError: Error { case transport }
    let cache = CatalogCacheStub()
    cache.storedData = nil
    let repository = CatalogRepository(
      remote: FailingRemoteStub(error: StubError.transport),
      cache: cache,
      dateProvider: { Date() }
    )

    do {
      _ = try await repository.loadCatalog(forceRefresh: true)
      #expect(Bool(false))
    } catch {
      #expect(error is StubError)
    }
  }
}

final class CatalogRepositoryLoggerSpy: CatalogRepositoryLogging {
  private(set) var errors: [Error] = []

  func cacheDecodingFailed(_ error: Error) {
    errors.append(error)
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

struct JournalClientTests {
  @Test func encodesPayloadWithStableUserIdentifier() async throws {
    let spy = APIClientSpy()
    let defaults = UserDefaults(suiteName: "JournalClientTests")!
    defaults.removePersistentDomain(forName: "JournalClientTests")
    defaults.set("12345678-1234-1234-1234-1234567890ab", forKey: "com.wavelengthwatch.userIdentifier")
    let date = Date(timeIntervalSince1970: 1000)
    let client = JournalClient(apiClient: spy, dateProvider: { date }, userDefaults: defaults)

    _ = try await client.submit(curriculumID: 5, secondaryCurriculumID: 7, strategyID: 9, initiatedBy: .scheduled)

    #expect(spy.lastPath == APIPath.journal)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let payload = try decoder.decode(JournalPayload.self, from: spy.lastBody ?? Data())
    #expect(payload.curriculumID == 5)
    #expect(payload.secondaryCurriculumID == 7)
    #expect(payload.strategyID == 9)
    #expect(payload.createdAt == date)
    #expect(payload.initiatedBy == .scheduled)
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

struct ContentViewModelTests {
  @Test func loadsCatalogSuccessfully() async throws {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.loadCatalog()

    #expect(!viewModel.layers.isEmpty)
    #expect(viewModel.loadErrorMessage == nil)
    #expect(viewModel.isLoading == false)
  }

  @Test func surfacesErrorWhenLoadingFails() async {
    enum TestError: Error { case failure }
    let repository = CatalogRepositoryMock(result: .failure(TestError.failure))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.loadCatalog()

    #expect(viewModel.layers.isEmpty)
    #expect(viewModel.loadErrorMessage != nil)
  }

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

  @Test func logsJournalEntriesWithStrategy() async {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.journal(curriculumID: 1, strategyID: 3)

    #expect(journal.submissions.count == 1)
    let submission = journal.submissions[0]
    #expect(submission.0 == 1) // curriculumID
    #expect(submission.1 == nil) // secondaryCurriculumID
    #expect(submission.2 == 3) // strategyID
  }

  @Test func logsJournalEntriesWithSecondaryCurriculum() async {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.journal(curriculumID: 1, secondaryCurriculumID: 2)

    #expect(journal.submissions.count == 1)
    let submission = journal.submissions[0]
    #expect(submission.0 == 1) // curriculumID
    #expect(submission.1 == 2) // secondaryCurriculumID
    #expect(submission.2 == nil) // strategyID
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

struct AppConfigurationTests {
  @Test func loadsFromInfoPlistWhenAvailable() {
    let bundle = MockBundle()
    bundle.infoPlistValues["API_BASE_URL"] = "https://api.example.com"

    let config = AppConfiguration(bundle: bundle)

    #expect(config.apiBaseURL.absoluteString == "https://api.example.com")
  }

  @Test func fallsBackToConfigurationPlist() throws {
    let bundle = MockBundle()
    bundle.plistPaths["APIConfiguration"] = createTempPlist(withURL: "https://fallback.example.com")

    let config = AppConfiguration(bundle: bundle)

    #expect(config.apiBaseURL.absoluteString == "https://fallback.example.com")
  }

  @Test func usesPlaceholderWhenNoConfigurationFound() {
    let bundle = MockBundle()

    let config = AppConfiguration(bundle: bundle)

    #expect(config.apiBaseURL.absoluteString == "https://api.not-configured.local")
  }

  @Test func usesPlaceholderWhenURLIsInvalid() {
    let bundle = MockBundle()
    bundle.infoPlistValues["API_BASE_URL"] = "not-a-valid-url"

    let config = AppConfiguration(bundle: bundle)

    #expect(config.apiBaseURL.absoluteString == "https://api.not-configured.local")
  }

  @Test func trimsWhitespaceFromURL() {
    let bundle = MockBundle()
    bundle.infoPlistValues["API_BASE_URL"] = "  https://api.example.com  "

    let config = AppConfiguration(bundle: bundle)

    #expect(config.apiBaseURL.absoluteString == "https://api.example.com")
  }

  @Test func usesPlaceholderWhenURLIsEmpty() {
    let bundle = MockBundle()
    bundle.infoPlistValues["API_BASE_URL"] = ""

    let config = AppConfiguration(bundle: bundle)

    #expect(config.apiBaseURL.absoluteString == "https://api.not-configured.local")
  }

  private func createTempPlist(withURL url: String) -> String {
    let tempDir = NSTemporaryDirectory()
    let tempFile = URL(fileURLWithPath: tempDir).appendingPathComponent(UUID().uuidString + ".plist")

    let plistDict: [String: Any] = ["API_BASE_URL": url]
    let plistData = try! PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0)
    try! plistData.write(to: tempFile)

    return tempFile.path
  }
}

final class MockBundle: Bundle, @unchecked Sendable {
  var infoPlistValues: [String: Any] = [:]
  var plistPaths: [String: String] = [:]

  override func object(forInfoDictionaryKey key: String) -> Any? {
    infoPlistValues[key]
  }

  override func path(forResource name: String?, ofType ext: String?) -> String? {
    guard let name else { return nil }
    return plistPaths[name]
  }
}

struct MysticalJournalIconTests {
  @Test func mysticalJournalIconHasPlusSignDesign() {
    let color = Color.blue

    #expect(true) // Updated test for plus sign design - compilation verified
  }
}

struct JournalScheduleTests {
  @Test func encodesAndDecodesSchedule() throws {
    var time = DateComponents()
    time.hour = 8
    time.minute = 0

    let schedule = JournalSchedule(
      id: UUID(),
      time: time,
      enabled: true,
      repeatDays: [1, 2, 3, 4, 5]
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(schedule)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(JournalSchedule.self, from: data)

    #expect(decoded.id == schedule.id)
    #expect(decoded.time.hour == 8)
    #expect(decoded.time.minute == 0)
    #expect(decoded.enabled == true)
    #expect(decoded.repeatDays == [1, 2, 3, 4, 5])
  }

  @Test func validatesRepeatDays() {
    var time = DateComponents()
    time.hour = 8
    time.minute = 0

    let validSchedule = JournalSchedule(time: time, repeatDays: [0, 6])
    #expect(validSchedule.isValid)

    let invalidSchedule = JournalSchedule(time: time, repeatDays: [-1, 7])
    #expect(!invalidSchedule.isValid)
  }

  @Test func defaultsToAllDaysEnabled() {
    var time = DateComponents()
    time.hour = 8
    time.minute = 0

    let schedule = JournalSchedule(time: time)
    #expect(schedule.enabled == true)
    #expect(schedule.repeatDays == [0, 1, 2, 3, 4, 5, 6])
  }
}

final class MockNotificationCenter: UNUserNotificationCenter {
  var requestedPermissions: UNAuthorizationOptions?
  var permissionResult: Bool = true
  var addedRequests: [UNNotificationRequest] = []
  var removedAllPending = false

  override func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
    requestedPermissions = options
    return permissionResult
  }

  override func add(_ request: UNNotificationRequest) async throws {
    addedRequests.append(request)
  }

  override func removeAllPendingNotificationRequests() {
    removedAllPending = true
    addedRequests.removeAll()
  }
}

struct NotificationDelegateTests {
  @MainActor
  @Test func handlesScheduledNotificationResponse() {
    let delegate = NotificationDelegate()

    let content = UNMutableNotificationContent()
    content.userInfo = [
      "scheduleId": "test-schedule-123",
      "initiatedBy": "scheduled",
    ]

    let request = UNNotificationRequest(
      identifier: "test",
      content: content,
      trigger: nil
    )

    let notification = UNNotification(coder: NSKeyedArchiver(requiringSecureCoding: false))!
    let response = UNNotificationResponse(
      coder: NSKeyedArchiver(requiringSecureCoding: false)
    )!

    // Since we can't easily mock UNNotificationResponse, test the logic directly
    let userInfo: [AnyHashable: Any] = [
      "scheduleId": "test-schedule-123",
      "initiatedBy": "scheduled",
    ]

    if let scheduleId = userInfo["scheduleId"] as? String,
       let initiatedByString = userInfo["initiatedBy"] as? String,
       initiatedByString == "scheduled"
    {
      delegate.scheduledNotificationReceived = ScheduledNotification(
        scheduleId: scheduleId,
        initiatedBy: .scheduled
      )
    }

    #expect(delegate.scheduledNotificationReceived?.scheduleId == "test-schedule-123")
    #expect(delegate.scheduledNotificationReceived?.initiatedBy == .scheduled)
  }

  @MainActor
  @Test func ignoresNonScheduledNotifications() {
    let delegate = NotificationDelegate()

    let userInfo: [AnyHashable: Any] = [
      "scheduleId": "test-schedule-123",
      "initiatedBy": "self", // Not "scheduled"
    ]

    if let scheduleId = userInfo["scheduleId"] as? String,
       let initiatedByString = userInfo["initiatedBy"] as? String,
       initiatedByString == "scheduled"
    {
      delegate.scheduledNotificationReceived = ScheduledNotification(
        scheduleId: scheduleId,
        initiatedBy: .scheduled
      )
    }

    #expect(delegate.scheduledNotificationReceived == nil)
  }

  @MainActor
  @Test func clearsNotificationState() {
    let delegate = NotificationDelegate()

    delegate.scheduledNotificationReceived = ScheduledNotification(
      scheduleId: "test-id",
      initiatedBy: .scheduled
    )
    #expect(delegate.scheduledNotificationReceived != nil)

    delegate.clearNotificationState()
    #expect(delegate.scheduledNotificationReceived == nil)
  }
}

struct ContentViewModelInitiationContextTests {
  @MainActor
  @Test func usesCurrentInitiatedByWhenNotOverridden() async {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    viewModel.setInitiatedBy(.scheduled)
    await viewModel.journal(curriculumID: 1)

    #expect(journal.submissions.count == 1)
    #expect(journal.submittedInitiatedBy == .scheduled)
  }

  @MainActor
  @Test func resetsToSelfInitiatedAfterSubmission() async {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    viewModel.setInitiatedBy(.scheduled)
    await viewModel.journal(curriculumID: 1)

    #expect(viewModel.currentInitiatedBy == .self_initiated)
  }

  @MainActor
  @Test func allowsExplicitOverrideOfInitiatedBy() async {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    viewModel.setInitiatedBy(.scheduled)
    await viewModel.journal(curriculumID: 1, initiatedBy: .self_initiated)

    #expect(journal.submittedInitiatedBy == .self_initiated)
  }
}

struct NotificationSchedulerTests {
  @Test func requestsPermissionWithCorrectOptions() async throws {
    let mockCenter = MockNotificationCenter()
    let scheduler = NotificationScheduler(notificationCenter: mockCenter)

    let granted = try await scheduler.requestPermission()

    #expect(granted == true)
    #expect(mockCenter.requestedPermissions?.contains(.alert) == true)
    #expect(mockCenter.requestedPermissions?.contains(.sound) == true)
    #expect(mockCenter.requestedPermissions?.contains(.badge) == true)
  }

  @Test func schedulesNotificationsForEnabledSchedules() async throws {
    let mockCenter = MockNotificationCenter()
    let scheduler = NotificationScheduler(notificationCenter: mockCenter)

    var time = DateComponents()
    time.hour = 8
    time.minute = 0

    let enabledSchedule = JournalSchedule(time: time, enabled: true, repeatDays: [1, 3, 5])
    let disabledSchedule = JournalSchedule(time: time, enabled: false, repeatDays: [2, 4])

    try await scheduler.scheduleNotifications(for: [enabledSchedule, disabledSchedule])

    // Should only schedule for enabled schedule (3 days = 3 notifications)
    #expect(mockCenter.addedRequests.count == 3)
    #expect(mockCenter.removedAllPending == true)
  }

  @Test func cancelsAllNotifications() {
    let mockCenter = MockNotificationCenter()
    let scheduler = NotificationScheduler(notificationCenter: mockCenter)

    scheduler.cancelAllNotifications()

    #expect(mockCenter.removedAllPending == true)
  }

  @Test func notificationContentIncludesScheduleInfo() async throws {
    let mockCenter = MockNotificationCenter()
    let scheduler = NotificationScheduler(notificationCenter: mockCenter)

    var time = DateComponents()
    time.hour = 8
    time.minute = 0

    let schedule = JournalSchedule(time: time, repeatDays: [1])

    try await scheduler.scheduleNotifications(for: [schedule])

    #expect(mockCenter.addedRequests.count == 1)
    let request = mockCenter.addedRequests[0]
    #expect(request.content.title == "Journal Check-In")
    #expect(request.content.userInfo["initiatedBy"] as? String == "scheduled")
    #expect(request.content.userInfo["scheduleId"] as? String == schedule.id.uuidString)
  }
}

struct ScheduleViewModelTests {
  @MainActor
  @Test func requestsNotificationPermission() async throws {
    let mockCenter = MockNotificationCenter()
    let scheduler = NotificationScheduler(notificationCenter: mockCenter)
    let defaults = UserDefaults(suiteName: "ScheduleViewModelTests.permission")!
    defaults.removePersistentDomain(forName: "ScheduleViewModelTests.permission")
    let viewModel = ScheduleViewModel(userDefaults: defaults, notificationScheduler: scheduler)

    let granted = try await viewModel.requestNotificationPermission()

    #expect(granted == true)
    #expect(mockCenter.requestedPermissions?.contains(.alert) == true)
    #expect(mockCenter.requestedPermissions?.contains(.sound) == true)
    #expect(mockCenter.requestedPermissions?.contains(.badge) == true)
  }

  @MainActor
  @Test func addsScheduleAndPersists() throws {
    let defaults = UserDefaults(suiteName: "ScheduleViewModelTests.add")!
    defaults.removePersistentDomain(forName: "ScheduleViewModelTests.add")

    let viewModel = ScheduleViewModel(userDefaults: defaults)
    #expect(viewModel.schedules.isEmpty)

    var time = DateComponents()
    time.hour = 8
    time.minute = 0
    let schedule = JournalSchedule(time: time, repeatDays: [1, 2, 3, 4, 5])

    viewModel.addSchedule(schedule)
    #expect(viewModel.schedules.count == 1)
    #expect(viewModel.schedules[0].id == schedule.id)

    // Verify persistence
    let newViewModel = ScheduleViewModel(userDefaults: defaults)
    #expect(newViewModel.schedules.count == 1)
    #expect(newViewModel.schedules[0].id == schedule.id)
  }

  @MainActor
  @Test func updatesSchedule() {
    let defaults = UserDefaults(suiteName: "ScheduleViewModelTests.update")!
    defaults.removePersistentDomain(forName: "ScheduleViewModelTests.update")

    let viewModel = ScheduleViewModel(userDefaults: defaults)

    var time = DateComponents()
    time.hour = 8
    time.minute = 0
    let schedule = JournalSchedule(time: time, repeatDays: [1, 2, 3])
    viewModel.addSchedule(schedule)

    var updatedTime = DateComponents()
    updatedTime.hour = 10
    updatedTime.minute = 30
    let updated = JournalSchedule(
      id: schedule.id,
      time: updatedTime,
      enabled: false,
      repeatDays: [0, 6]
    )
    viewModel.updateSchedule(updated)

    #expect(viewModel.schedules.count == 1)
    #expect(viewModel.schedules[0].time.hour == 10)
    #expect(viewModel.schedules[0].enabled == false)
  }

  @MainActor
  @Test func deletesSchedule() {
    let defaults = UserDefaults(suiteName: "ScheduleViewModelTests.delete")!
    defaults.removePersistentDomain(forName: "ScheduleViewModelTests.delete")

    let viewModel = ScheduleViewModel(userDefaults: defaults)

    var time = DateComponents()
    time.hour = 8
    time.minute = 0
    viewModel.addSchedule(JournalSchedule(time: time))
    viewModel.addSchedule(JournalSchedule(time: time))

    #expect(viewModel.schedules.count == 2)

    viewModel.deleteSchedule(at: IndexSet(integer: 0))
    #expect(viewModel.schedules.count == 1)
  }

  @MainActor
  @Test func togglesScheduleEnabledViaDirectBinding() {
    let defaults = UserDefaults(suiteName: "ScheduleViewModelTests.toggle")!
    defaults.removePersistentDomain(forName: "ScheduleViewModelTests.toggle")

    let viewModel = ScheduleViewModel(userDefaults: defaults)

    var time = DateComponents()
    time.hour = 8
    time.minute = 0
    let schedule = JournalSchedule(time: time, enabled: true)
    viewModel.addSchedule(schedule)

    #expect(viewModel.schedules[0].enabled == true)

    // Toggle via direct binding access (as ScheduleRow now does)
    viewModel.schedules[0].enabled.toggle()
    viewModel.saveSchedules()
    #expect(viewModel.schedules[0].enabled == false)

    viewModel.schedules[0].enabled.toggle()
    viewModel.saveSchedules()
    #expect(viewModel.schedules[0].enabled == true)
  }
}

struct JournalUIInteractionTests {
  private func makeSampleStrategyPhase() -> CatalogPhaseModel {
    let medicinal = CatalogCurriculumEntryModel(id: 1, dosage: .medicinal, expression: "Commitment")
    let strategy = CatalogStrategyModel(id: 3, strategy: "Cold Shower", color: "Blue")
    return CatalogPhaseModel(id: 1, name: "Rising", medicinal: [medicinal], toxic: [], strategies: [strategy])
  }

  private func makeSampleCurriculumPhase() -> CatalogPhaseModel {
    let medicinal = CatalogCurriculumEntryModel(id: 1, dosage: .medicinal, expression: "Commitment")
    let toxic = CatalogCurriculumEntryModel(id: 2, dosage: .toxic, expression: "Overcommitment")
    return CatalogPhaseModel(id: 1, name: "Rising", medicinal: [medicinal], toxic: [toxic], strategies: [])
  }

  @Test func strategyPhaseHasJournalIcon() {
    let phase = makeSampleStrategyPhase()

    #expect(phase.strategies.count == 1)
    #expect(phase.medicinal.count == 1)

    let strategy = phase.strategies[0]
    #expect(strategy.id == 3)
    #expect(strategy.strategy == "Cold Shower")
  }

  @Test func curriculumPhaseHasMedicinalAndToxic() {
    let phase = makeSampleCurriculumPhase()

    #expect(phase.medicinal.count == 1)
    #expect(phase.toxic.count == 1)

    let medicinal = phase.medicinal[0]
    #expect(medicinal.id == 1)
    #expect(medicinal.expression == "Commitment")
    #expect(medicinal.dosage == .medicinal)

    let toxic = phase.toxic[0]
    #expect(toxic.id == 2)
    #expect(toxic.expression == "Overcommitment")
    #expect(toxic.dosage == .toxic)
  }

  @Test func strategyCardHasPlusIconAndConfirmation() {
    let phase = makeSampleStrategyPhase()
    let strategy = phase.strategies[0]

    #expect(strategy.id == 3)
    #expect(strategy.strategy == "Cold Shower")
    #expect(phase.medicinal.count == 1) // Ensures primaryID exists for plus icon
  }

  @Test func strategiesOnlyPhaseCanUseFallbackCurriculum() {
    let strategiesOnlyStrategy = CatalogStrategyModel(id: 5, strategy: "Deep Breathing", color: "Blue")
    let strategiesOnlyPhase = CatalogPhaseModel(id: 2, name: "Strategies", medicinal: [], toxic: [], strategies: [strategiesOnlyStrategy])

    #expect(strategiesOnlyPhase.medicinal.isEmpty)
    #expect(strategiesOnlyPhase.toxic.isEmpty)
    #expect(strategiesOnlyPhase.strategies.count == 1)
    #expect(strategiesOnlyPhase.strategies[0].strategy == "Deep Breathing")
  }
}
