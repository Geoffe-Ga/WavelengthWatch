import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

/// Tests for WatchOSMarkdownParser.
///
/// Validates block-level markdown parsing for watchOS rendering.
struct WatchOSMarkdownParserTests {
  let parser = WatchOSMarkdownParser()

  @Test("Parses header 1")
  func parseHeader1() {
    let markdown = "# Main Title"
    let blocks = parser.parse(markdown)

    #expect(blocks.count == 1)
    if case let .header1(text) = blocks[0] {
      #expect(text == "Main Title")
    } else {
      Issue.record("Expected header1 block")
    }
  }

  @Test("Parses header 2")
  func parseHeader2() {
    let markdown = "## Section Title"
    let blocks = parser.parse(markdown)

    #expect(blocks.count == 1)
    if case let .header2(text) = blocks[0] {
      #expect(text == "Section Title")
    } else {
      Issue.record("Expected header2 block")
    }
  }

  @Test("Parses header 3")
  func parseHeader3() {
    let markdown = "### Subsection"
    let blocks = parser.parse(markdown)

    #expect(blocks.count == 1)
    if case let .header3(text) = blocks[0] {
      #expect(text == "Subsection")
    } else {
      Issue.record("Expected header3 block")
    }
  }

  @Test("Parses unordered list with dash")
  func parseUnorderedListDash() {
    let markdown = """
    - First item
    - Second item
    - Third item
    """
    let blocks = parser.parse(markdown)

    #expect(blocks.count == 3)
    for block in blocks {
      guard case .listItem = block else {
        Issue.record("Expected listItem block")
        return
      }
    }
  }

  @Test("Parses unordered list with asterisk")
  func parseUnorderedListAsterisk() {
    let markdown = """
    * First item
    * Second item
    """
    let blocks = parser.parse(markdown)

    #expect(blocks.count == 2)
    for block in blocks {
      guard case .listItem = block else {
        Issue.record("Expected listItem block")
        return
      }
    }
  }

  @Test("Parses blockquote")
  func parseBlockquote() {
    let markdown = "> This is a quote"
    let blocks = parser.parse(markdown)

    #expect(blocks.count == 1)
    guard case .blockquote = blocks[0] else {
      Issue.record("Expected blockquote block")
      return
    }
  }

  @Test("Parses paragraph")
  func parseParagraph() {
    let markdown = "This is a simple paragraph."
    let blocks = parser.parse(markdown)

    #expect(blocks.count == 1)
    guard case let .paragraph(text) = blocks[0] else {
      Issue.record("Expected paragraph block")
      return
    }
    #expect(String(text.characters) == "This is a simple paragraph.")
  }

  @Test("Parses multiple paragraphs separated by blank lines")
  func parseMultipleParagraphs() {
    let markdown = """
    First paragraph.

    Second paragraph.
    """
    let blocks = parser.parse(markdown)

    #expect(blocks.count == 2)
    guard case .paragraph = blocks[0],
          case .paragraph = blocks[1]
    else {
      Issue.record("Expected two paragraph blocks")
      return
    }
  }

  @Test("Preserves inline bold formatting")
  func preserveBoldFormatting() {
    let markdown = "This has **bold** text."
    let blocks = parser.parse(markdown)

    #expect(blocks.count == 1)
    guard case let .paragraph(attributed) = blocks[0] else {
      Issue.record("Expected paragraph block")
      return
    }

    // Check that bold formatting is preserved
    var hasBold = false
    for run in attributed.runs {
      if run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
        hasBold = true
        break
      }
    }
    #expect(hasBold, "Bold formatting should be preserved")
  }

  @Test("Preserves inline italic formatting")
  func preserveItalicFormatting() {
    let markdown = "This has *italic* text."
    let blocks = parser.parse(markdown)

    #expect(blocks.count == 1)
    guard case let .paragraph(attributed) = blocks[0] else {
      Issue.record("Expected paragraph block")
      return
    }

    // Check that italic formatting is preserved
    var hasItalic = false
    for run in attributed.runs {
      if run.inlinePresentationIntent?.contains(.emphasized) == true {
        hasItalic = true
        break
      }
    }
    #expect(hasItalic, "Italic formatting should be preserved")
  }

  @Test("Parses complex document structure")
  func parseComplexDocument() {
    let markdown = """
    # Title

    Introduction paragraph.

    ## Section

    - Item 1
    - Item 2

    Another paragraph.

    > A quote

    Final paragraph.
    """
    let blocks = parser.parse(markdown)

    // Expected: header1, paragraph, header2, listItem, listItem, paragraph, blockquote, paragraph
    #expect(blocks.count == 8)

    guard case .header1 = blocks[0] else {
      Issue.record("Expected header1 at index 0")
      return
    }
    guard case .paragraph = blocks[1] else {
      Issue.record("Expected paragraph at index 1")
      return
    }
    guard case .header2 = blocks[2] else {
      Issue.record("Expected header2 at index 2")
      return
    }
    guard case .listItem = blocks[3] else {
      Issue.record("Expected listItem at index 3")
      return
    }
    guard case .listItem = blocks[4] else {
      Issue.record("Expected listItem at index 4")
      return
    }
    guard case .paragraph = blocks[5] else {
      Issue.record("Expected paragraph at index 5")
      return
    }
    guard case .blockquote = blocks[6] else {
      Issue.record("Expected blockquote at index 6")
      return
    }
    guard case .paragraph = blocks[7] else {
      Issue.record("Expected paragraph at index 7")
      return
    }
  }

  @Test("Parses about-content.md structure")
  @MainActor
  func parseAboutContent() async {
    let loader = MarkdownContentLoader()
    let result = await loader.loadParsedContent(fileName: "about-content")

    guard case let .success(content) = result else {
      Issue.record("Failed to load about-content.md")
      return
    }

    // Verify we have blocks
    #expect(content.blocks.count > 0)

    // Verify we have headers
    let headers = content.blocks.filter {
      if case .header1 = $0 { return true }
      if case .header2 = $0 { return true }
      return false
    }
    #expect(headers.count >= 4, "Should have at least 4 headers (title + sections)")

    // Verify we have list items
    let listItems = content.blocks.filter {
      if case .listItem = $0 { return true }
      return false
    }
    #expect(listItems.count >= 10, "Should have at least 10 list items (frequencies + dosages)")

    // Verify we have paragraphs
    let paragraphs = content.blocks.filter {
      if case .paragraph = $0 { return true }
      return false
    }
    #expect(paragraphs.count >= 3, "Should have at least 3 paragraphs")
  }
}
