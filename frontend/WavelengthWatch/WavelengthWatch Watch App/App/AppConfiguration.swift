import Foundation
import OSLog

protocol BundleProtocol {
  func object(forInfoDictionaryKey key: String) -> Any?
  func path(forResource name: String?, ofType ext: String?) -> String?
}

extension Bundle: BundleProtocol {}

struct AppConfiguration {
  private static let logger = Logger(subsystem: "com.wavelengthwatch.watch", category: "AppConfiguration")
  private static let placeholderURL = URL(string: "https://api.not-configured.local")!

  let apiBaseURL: URL

  init(bundle: BundleProtocol = Bundle.main) {
    let rawValue = Self.loadAPIBaseURL(from: bundle)?.trimmingCharacters(in: .whitespacesAndNewlines)

    guard
      let urlString = rawValue,
      !urlString.isEmpty,
      let url = URL(string: urlString)
    else {
      Self.logger.fault("Missing API_BASE_URL; falling back to placeholder host \(Self.placeholderURL.absoluteString, privacy: .public)")
      self.apiBaseURL = Self.placeholderURL
      return
    }

    if url == Self.placeholderURL {
      Self.logger.warning("API_BASE_URL is still pointing at the placeholder host. Configure a real backend before shipping.")
    }

    self.apiBaseURL = url
  }

  private static func loadAPIBaseURL(from bundle: BundleProtocol) -> String? {
    // First try to load from Info.plist (for build-time configuration)
    if let urlFromInfo = bundle.object(forInfoDictionaryKey: "API_BASE_URL") as? String {
      return urlFromInfo
    }

    // Try local development configuration first (not committed to git)
    if let path = bundle.path(forResource: "APIConfiguration-Local", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let apiBaseURL = plist["API_BASE_URL"] as? String
    {
      return apiBaseURL
    }

    // Try main configuration file (may be gitignored for local dev)
    if let path = bundle.path(forResource: "APIConfiguration", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let apiBaseURL = plist["API_BASE_URL"] as? String
    {
      return apiBaseURL
    }

    return nil
  }
}
