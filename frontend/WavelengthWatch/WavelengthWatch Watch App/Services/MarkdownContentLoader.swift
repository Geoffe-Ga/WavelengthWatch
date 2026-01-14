import Foundation
import SwiftUI

/// Errors that can occur during markdown content loading
enum MarkdownLoadError: Error, Equatable {
  case fileNotFound
  case parsingFailed
  case readFailed
}

/// Loads and parses markdown content files from the app bundle
@MainActor
class MarkdownContentLoader {
  private let bundle: Bundle

  /// Initialize the loader with a specific bundle
  ///
  /// - Parameter bundle: The bundle to load resources from (defaults to .main)
  init(bundle: Bundle = .main) {
    self.bundle = bundle
  }

  /// Loads markdown content from a file in the app bundle
  ///
  /// - Parameter fileName: The name of the markdown file (without .md extension)
  /// - Returns: Result containing AttributedString on success or error on failure
  func loadContent(fileName: String) async -> Result<AttributedString, MarkdownLoadError> {
    // Validate filename
    guard !fileName.isEmpty else {
      return .failure(.fileNotFound)
    }

    // Locate file in bundle
    guard let url = bundle.url(forResource: fileName, withExtension: "md") else {
      return .failure(.fileNotFound)
    }

    // Read file contents
    guard let markdownString = try? String(contentsOf: url, encoding: .utf8) else {
      return .failure(.readFailed)
    }

    // Parse markdown to AttributedString
    guard let attributedString = try? AttributedString(markdown: markdownString) else {
      return .failure(.parsingFailed)
    }

    return .success(attributedString)
  }
}
