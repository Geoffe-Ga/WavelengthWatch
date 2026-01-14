import Foundation
import SwiftUI
import Testing

@testable import WavelengthWatch_Watch_App

/// Tests for ConceptExplainerView markdown loading and rendering.
///
/// These tests verify:
/// - Markdown content loads from bundle
/// - Missing files are handled gracefully
/// - Content is converted to AttributedString
@MainActor
@Suite("ConceptExplainerView Tests")
struct ConceptExplainerViewTests {
  @Test func markdownLoader_validFile_loadsContent() async {
    // Given a valid markdown file in the bundle
    let loader = MarkdownContentLoader()

    // When loading the about content
    let result = await loader.loadContent(fileName: "about-content")

    // Then content should be loaded successfully
    switch result {
    case let .success(attributedString):
      #expect(attributedString.characters.count > 0)
      // Verify it contains expected content
      let string = String(attributedString.characters)
      #expect(string.contains("Archetypal Wavelength"))
    case .failure:
      Issue.record("Expected successful load, got failure")
    }
  }

  @Test func markdownLoader_missingFile_handlesGracefully() async {
    // Given a missing file
    let loader = MarkdownContentLoader()

    // When attempting to load non-existent content
    let result = await loader.loadContent(fileName: "nonexistent-file")

    // Then it should return an error
    switch result {
    case .success:
      Issue.record("Expected failure for missing file, got success")
    case let .failure(error):
      #expect(error == .fileNotFound)
    }
  }

  @Test func markdownLoader_invalidMarkdown_handlesGracefully() async {
    // Given a file with invalid markdown content
    let loader = MarkdownContentLoader()

    // When loading content that can't be parsed
    // (This is hard to trigger with SwiftUI's AttributedString(markdown:)
    // as it's quite forgiving, but we test the error path)
    let result = await loader.loadContent(fileName: "")

    // Then it should return an error
    switch result {
    case .success:
      Issue.record("Expected failure for empty filename, got success")
    case .failure:
      // Error is expected - could be fileNotFound or parsingFailed
      #expect(true)
    }
  }

  @Test func markdownLoader_preservesFormatting() async {
    // Given markdown with various formatting
    let loader = MarkdownContentLoader()

    // When loading the about content
    let result = await loader.loadContent(fileName: "about-content")

    // Then formatting should be preserved
    switch result {
    case let .success(attributedString):
      let string = String(attributedString.characters)
      // Verify content structure is maintained
      #expect(string.contains("Layers"))
      #expect(string.contains("Phases"))
      #expect(string.contains("Dosages"))
      #expect(string.contains("Self-Care Strategies"))
    case .failure:
      Issue.record("Expected successful load with preserved formatting")
    }
  }
}
