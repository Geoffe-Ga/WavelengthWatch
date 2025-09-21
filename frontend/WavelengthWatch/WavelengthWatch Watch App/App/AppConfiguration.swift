import Foundation
import OSLog

struct AppConfiguration {
  private static let placeholderURL = URL(string: "https://api.not-configured.local")!
  private static let logger = Logger(subsystem: "com.wavelengthwatch.watch", category: "AppConfiguration")

  let apiBaseURL: URL

  init(bundle: Bundle = .main) {
    let rawValue = Self.loadAPIBaseURL(from: bundle)?.trimmingCharacters(in: .whitespacesAndNewlines)

    guard
      let urlString = rawValue,
      !urlString.isEmpty,
      let url = URL(string: urlString)
    else {
      #if DEBUG
      assertionFailure("API_BASE_URL is missing or invalid. Update APIConfiguration.plist for the current build configuration.")
      #endif
      AppConfiguration.logger.fault("Missing API_BASE_URL; falling back to placeholder host \(AppConfiguration.placeholderURL.absoluteString, privacy: .public)")
      self.apiBaseURL = AppConfiguration.placeholderURL
      return
    }

    if url == AppConfiguration.placeholderURL {
      AppConfiguration.logger.error("API_BASE_URL is still pointing at the placeholder host. Configure a real backend before shipping.")
    }

    self.apiBaseURL = url
  }

  private static func loadAPIBaseURL(from bundle: Bundle) -> String? {
    // First try to load from Info.plist (for build-time configuration)
    if let urlFromInfo = bundle.object(forInfoDictionaryKey: "API_BASE_URL") as? String {
      return urlFromInfo
    }

    // Fallback to APIConfiguration.plist
    guard let path = bundle.path(forResource: "APIConfiguration", ofType: "plist"),
          let plist = NSDictionary(contentsOfFile: path),
          let apiBaseURL = plist["API_BASE_URL"] as? String
    else {
      return nil
    }

    return apiBaseURL
  }
}
