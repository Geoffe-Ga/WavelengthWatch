import Foundation
import OSLog

protocol CatalogRemoteServicing {
  func fetchCatalog() async throws -> CatalogResponseModel
}

protocol CatalogCachePersisting {
  func loadCatalogData() throws -> Data?
  func writeCatalogData(_ data: Data) throws
  func removeCatalogData() throws
}

protocol CatalogRepositoryProtocol {
  func cachedCatalog() -> CatalogResponseModel?
  func loadCatalog(forceRefresh: Bool) async throws -> CatalogResponseModel
  func refreshCatalog() async throws -> CatalogResponseModel
}

protocol CatalogRepositoryLogging {
  func cacheDecodingFailed(_ error: Error)
}

struct CatalogAPIService: CatalogRemoteServicing {
  let apiClient: APIClientProtocol

  func fetchCatalog() async throws -> CatalogResponseModel {
    try await apiClient.get("/catalog")
  }
}

final class FileCatalogCacheStore: CatalogCachePersisting {
  private let fileURL: URL
  private let fileManager: FileManager

  init(fileURL: URL, fileManager: FileManager = .default) {
    self.fileURL = fileURL
    self.fileManager = fileManager
  }

  convenience init(fileName: String = "catalog-cache.json", fileManager: FileManager = .default) {
    let directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
    self.init(fileURL: directory.appendingPathComponent(fileName), fileManager: fileManager)
  }

  func loadCatalogData() throws -> Data? {
    guard fileManager.fileExists(atPath: fileURL.path) else {
      return nil
    }
    return try Data(contentsOf: fileURL)
  }

  func writeCatalogData(_ data: Data) throws {
    let directory = fileURL.deletingLastPathComponent()
    if !fileManager.fileExists(atPath: directory.path) {
      try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    try data.write(to: fileURL, options: [.atomic])
  }

  func removeCatalogData() throws {
    if fileManager.fileExists(atPath: fileURL.path) {
      try fileManager.removeItem(at: fileURL)
    }
  }
}

final class CatalogRepository: CatalogRepositoryProtocol {
  private let remote: CatalogRemoteServicing
  private let cache: CatalogCachePersisting
  private let dateProvider: () -> Date
  private let decoder: JSONDecoder
  private let encoder: JSONEncoder
  private let cacheTTL: TimeInterval
  private let logger: CatalogRepositoryLogging

  init(
    remote: CatalogRemoteServicing,
    cache: CatalogCachePersisting,
    dateProvider: @escaping () -> Date = Date.init,
    decoder: JSONDecoder = JSONDecoder(),
    encoder: JSONEncoder = JSONEncoder(),
    cacheTTL: TimeInterval = 60 * 60 * 24,
    logger: CatalogRepositoryLogging = DefaultCatalogRepositoryLogger()
  ) {
    self.remote = remote
    self.cache = cache
    self.dateProvider = dateProvider
    self.decoder = decoder
    self.encoder = encoder
    self.decoder.dateDecodingStrategy = .iso8601
    self.encoder.dateEncodingStrategy = .iso8601
    self.cacheTTL = cacheTTL
    self.logger = logger
  }

  private func readEnvelope() -> CatalogCacheEnvelope? {
    do {
      guard let data = try cache.loadCatalogData() else {
        return nil
      }
      return try decoder.decode(CatalogCacheEnvelope.self, from: data)
    } catch {
      logger.cacheDecodingFailed(error)
      try? cache.removeCatalogData()
      return nil
    }
  }

  private func writeEnvelope(_ catalog: CatalogResponseModel) throws {
    let envelope = CatalogCacheEnvelope(fetchedAt: dateProvider(), catalog: catalog)
    let data = try encoder.encode(envelope)
    try cache.writeCatalogData(data)
  }

  private func isFresh(_ envelope: CatalogCacheEnvelope) -> Bool {
    dateProvider().timeIntervalSince(envelope.fetchedAt) < cacheTTL
  }

  func cachedCatalog() -> CatalogResponseModel? {
    readEnvelope()?.catalog
  }

  func loadCatalog(forceRefresh: Bool = false) async throws -> CatalogResponseModel {
    if !forceRefresh, let envelope = readEnvelope(), isFresh(envelope) {
      return envelope.catalog
    }
    let catalog = try await remote.fetchCatalog()
    try? writeEnvelope(catalog)
    return catalog
  }

  func refreshCatalog() async throws -> CatalogResponseModel {
    let catalog = try await remote.fetchCatalog()
    try? writeEnvelope(catalog)
    return catalog
  }
}

struct DefaultCatalogRepositoryLogger: CatalogRepositoryLogging {
  private static let logger = Logger(subsystem: "com.wavelengthwatch.watch", category: "CatalogRepository")

  func cacheDecodingFailed(_ error: Error) {
    DefaultCatalogRepositoryLogger.logger.error("Failed to decode catalog cache: \(error.localizedDescription, privacy: .public)")
  }
}
