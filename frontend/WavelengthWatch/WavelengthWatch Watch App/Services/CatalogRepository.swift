import Foundation
import OSLog

protocol CatalogRemoteServicing {
  func fetchCatalog() async throws -> CatalogResponseModel
}

protocol CatalogCachePersisting {
  /// Synchronous version for cachedCatalog() - may block briefly
  func loadCatalogDataSync() throws -> Data?
  /// Async version for background loading
  func loadCatalogData() async throws -> Data?
  func writeCatalogData(_ data: Data) async throws
  func removeCatalogData() async throws
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
    try await apiClient.get(APIPath.catalog)
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

  func loadCatalogDataSync() throws -> Data? {
    guard fileManager.fileExists(atPath: fileURL.path) else {
      return nil
    }
    return try Data(contentsOf: fileURL)
  }

  func loadCatalogData() async throws -> Data? {
    try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async { [fileURL, fileManager] in
        guard fileManager.fileExists(atPath: fileURL.path) else {
          continuation.resume(returning: nil)
          return
        }
        do {
          let data = try Data(contentsOf: fileURL)
          continuation.resume(returning: data)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  func writeCatalogData(_ data: Data) async throws {
    try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async { [fileURL, fileManager] in
        do {
          let directory = fileURL.deletingLastPathComponent()
          if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
          }
          try data.write(to: fileURL, options: [.atomic])
          continuation.resume()
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  func removeCatalogData() async throws {
    try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async { [fileURL, fileManager] in
        do {
          if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
          }
          continuation.resume()
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
}

final class InMemoryCatalogCache: CatalogCachePersisting {
  private var storage: Data?

  func loadCatalogDataSync() throws -> Data? {
    storage
  }

  func loadCatalogData() async throws -> Data? {
    storage
  }

  func writeCatalogData(_ data: Data) async throws {
    storage = data
  }

  func removeCatalogData() async throws {
    storage = nil
  }
}

/// Repository for catalog data with dual-layer caching (memory + disk).
///
/// Thread Safety: Uses a serial queue to protect memoryCache access from concurrent reads/writes.
/// All public methods are thread-safe and can be called from any thread/actor.
///
/// Caching Strategy:
/// - Memory cache: Fast, in-process cache cleared only on app restart
/// - Disk cache: Persistent across app launches, subject to TTL expiration
/// - Memory cache is populated from disk on first access and updated on writes
///
/// Performance Characteristics:
/// - cachedCatalog(): Synchronous, returns immediately from memory or reads disk (may block briefly)
/// - loadCatalog(): Async, checks memory → disk → network, respects TTL
/// - refreshCatalog(): Async, always fetches from network and updates both caches
final class CatalogRepository: CatalogRepositoryProtocol {
  private let remote: CatalogRemoteServicing
  private let cache: CatalogCachePersisting
  private let dateProvider: () -> Date
  private let decoder: JSONDecoder
  private let encoder: JSONEncoder
  private let cacheTTL: TimeInterval
  private let logger: CatalogRepositoryLogging

  /// In-memory cache for fast access. Cleared only on app restart.
  /// Thread-safe via serialQueue protection.
  private var memoryCache: CatalogCacheEnvelope?

  /// Serial queue to protect memoryCache from concurrent access.
  private let serialQueue = DispatchQueue(label: "com.wavelengthwatch.catalogrepository.cache")

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

  private func readEnvelope() async -> CatalogCacheEnvelope? {
    // Check memory cache first (thread-safe read)
    let cachedEnvelope = serialQueue.sync { memoryCache }
    if let cachedEnvelope {
      return cachedEnvelope
    }

    // Fall back to disk cache
    do {
      guard let data = try await cache.loadCatalogData() else {
        return nil
      }
      let envelope = try decoder.decode(CatalogCacheEnvelope.self, from: data)
      // Update memory cache (thread-safe write)
      serialQueue.sync { memoryCache = envelope }
      return envelope
    } catch {
      logger.cacheDecodingFailed(error)
      try? await cache.removeCatalogData()
      return nil
    }
  }

  private func writeEnvelope(_ catalog: CatalogResponseModel) async throws {
    let envelope = CatalogCacheEnvelope(fetchedAt: dateProvider(), catalog: catalog)
    // Update memory cache (thread-safe write)
    serialQueue.sync { memoryCache = envelope }
    let data = try encoder.encode(envelope)
    try await cache.writeCatalogData(data)
  }

  private func isFresh(_ envelope: CatalogCacheEnvelope) -> Bool {
    dateProvider().timeIntervalSince(envelope.fetchedAt) < cacheTTL
  }

  func cachedCatalog() -> CatalogResponseModel? {
    // Protect entire read-decode-update operation to prevent TOCTOU race
    serialQueue.sync {
      // Check memory cache first for fast access
      if let cachedEnvelope = memoryCache {
        return cachedEnvelope.catalog
      }

      // Fall back to synchronous disk read and populate memory cache
      do {
        guard let data = try cache.loadCatalogDataSync() else {
          return nil
        }
        let envelope = try decoder.decode(CatalogCacheEnvelope.self, from: data)
        memoryCache = envelope
        return envelope.catalog
      } catch {
        // Log decoding errors for debugging, consistent with readEnvelope()
        logger.cacheDecodingFailed(error)
        return nil
      }
    }
  }

  func loadCatalog(forceRefresh: Bool = false) async throws -> CatalogResponseModel {
    if !forceRefresh, let envelope = await readEnvelope(), isFresh(envelope) {
      return envelope.catalog
    }
    let catalog = try await remote.fetchCatalog()
    try? await writeEnvelope(catalog)
    return catalog
  }

  func refreshCatalog() async throws -> CatalogResponseModel {
    let catalog = try await remote.fetchCatalog()
    try? await writeEnvelope(catalog)
    return catalog
  }
}

struct DefaultCatalogRepositoryLogger: CatalogRepositoryLogging {
  private static let logger = Logger(subsystem: "com.wavelengthwatch.watch", category: "CatalogRepository")

  func cacheDecodingFailed(_ error: Error) {
    DefaultCatalogRepositoryLogger.logger.error("Failed to decode catalog cache: \(error.localizedDescription, privacy: .public)")
  }
}
