import Foundation
import SwiftUI

/// Errors that can occur during markdown content loading
enum MarkdownLoadError: Error, Equatable {
  case fileNotFound
  case parsingFailed
  case readFailed
}

/// Result of loading and parsing markdown content
struct MarkdownContent {
  /// The raw markdown string
  let rawMarkdown: String

  /// Parsed blocks for block-level rendering
  let blocks: [MarkdownBlock]

  /// Legacy AttributedString for backward compatibility
  /// Note: This does not render block-level formatting correctly on watchOS
  let attributedString: AttributedString
}

/// Loads and parses markdown content files from the app bundle
@MainActor
class MarkdownContentLoader {
  private let bundle: Bundle
  private let parser: WatchOSMarkdownParser

  /// Initialize the loader with a specific bundle
  ///
  /// - Parameter bundle: The bundle to load resources from (defaults to .main)
  init(bundle: Bundle = .main) {
    self.bundle = bundle
    self.parser = WatchOSMarkdownParser()
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

    // Parse markdown to AttributedString with full block-level formatting support
    // This preserves lists, headers, and line breaks properly on watchOS
    var options = AttributedString.MarkdownParsingOptions()
    options.interpretedSyntax = .full

    guard
      let attributedString = try? AttributedString(markdown: markdownString, options: options)
    else {
      return .failure(.parsingFailed)
    }

    return .success(attributedString)
  }

  /// Loads and parses markdown content with full block-level support.
  ///
  /// This method returns structured markdown blocks that can be rendered
  /// properly on watchOS using MarkdownContentView.
  ///
  /// - Parameter fileName: The name of the markdown file (without .md extension)
  /// - Returns: Result containing MarkdownContent on success or error on failure
  func loadParsedContent(fileName: String) async -> Result<MarkdownContent, MarkdownLoadError> {
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

    // Parse blocks for proper rendering
    let blocks = parser.parse(markdownString)

    // Also create AttributedString for backward compatibility
    var options = AttributedString.MarkdownParsingOptions()
    options.interpretedSyntax = .full

    guard
      let attributedString = try? AttributedString(markdown: markdownString, options: options)
    else {
      return .failure(.parsingFailed)
    }

    let content = MarkdownContent(
      rawMarkdown: markdownString,
      blocks: blocks,
      attributedString: attributedString
    )

    return .success(content)
  }
}
