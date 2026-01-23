import Foundation
import SwiftUI

/// Represents a parsed markdown block element
enum MarkdownBlock: Identifiable, Equatable {
  case header1(String)
  case header2(String)
  case header3(String)
  case paragraph(AttributedString)
  case listItem(AttributedString)
  case blockquote(AttributedString)
  case empty

  var id: String {
    switch self {
    case let .header1(text): "h1-\(text.hashValue)"
    case let .header2(text): "h2-\(text.hashValue)"
    case let .header3(text): "h3-\(text.hashValue)"
    case let .paragraph(text): "p-\(text.hashValue)"
    case let .listItem(text): "li-\(text.hashValue)"
    case let .blockquote(text): "bq-\(text.hashValue)"
    case .empty: "empty-\(UUID().uuidString)"
    }
  }
}

/// Parses markdown text into structured blocks for watchOS rendering.
///
/// SwiftUI's Text view on watchOS does not render block-level AttributedString
/// formatting (lists, paragraph breaks, header sizes). This parser extracts
/// block structure manually so we can render with a VStack of Text views.
struct WatchOSMarkdownParser {
  /// Parses raw markdown into an array of MarkdownBlock elements.
  ///
  /// Handles:
  /// - Headers (# ## ###)
  /// - Unordered lists (- or *)
  /// - Blockquotes (>)
  /// - Paragraphs (regular text)
  /// - Inline formatting (bold, italic) via AttributedString
  ///
  /// - Parameter markdown: Raw markdown string
  /// - Returns: Array of parsed MarkdownBlock elements
  func parse(_ markdown: String) -> [MarkdownBlock] {
    let lines = markdown.components(separatedBy: .newlines)
    var blocks: [MarkdownBlock] = []
    var currentParagraph: [String] = []

    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces)

      // Empty line - flush current paragraph
      if trimmed.isEmpty {
        if !currentParagraph.isEmpty {
          let text = currentParagraph.joined(separator: " ")
          if let attributed = parseInlineFormatting(text) {
            blocks.append(.paragraph(attributed))
          }
          currentParagraph = []
        }
        continue
      }

      // Header 1: # Title
      if trimmed.hasPrefix("# ") {
        flushParagraph(&currentParagraph, into: &blocks)
        let headerText = String(trimmed.dropFirst(2))
        blocks.append(.header1(headerText))
        continue
      }

      // Header 2: ## Title
      if trimmed.hasPrefix("## ") {
        flushParagraph(&currentParagraph, into: &blocks)
        let headerText = String(trimmed.dropFirst(3))
        blocks.append(.header2(headerText))
        continue
      }

      // Header 3: ### Title
      if trimmed.hasPrefix("### ") {
        flushParagraph(&currentParagraph, into: &blocks)
        let headerText = String(trimmed.dropFirst(4))
        blocks.append(.header3(headerText))
        continue
      }

      // Unordered list item: - item or * item
      if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
        flushParagraph(&currentParagraph, into: &blocks)
        let itemText = String(trimmed.dropFirst(2))
        if let attributed = parseInlineFormatting(itemText) {
          blocks.append(.listItem(attributed))
        }
        continue
      }

      // Blockquote: > text
      if trimmed.hasPrefix("> ") {
        flushParagraph(&currentParagraph, into: &blocks)
        let quoteText = String(trimmed.dropFirst(2))
        if let attributed = parseInlineFormatting(quoteText) {
          blocks.append(.blockquote(attributed))
        }
        continue
      }

      // Regular text - accumulate into paragraph
      currentParagraph.append(trimmed)
    }

    // Flush any remaining paragraph
    flushParagraph(&currentParagraph, into: &blocks)

    return blocks
  }

  /// Flushes accumulated paragraph lines into a paragraph block.
  private func flushParagraph(_ lines: inout [String], into blocks: inout [MarkdownBlock]) {
    guard !lines.isEmpty else { return }
    let text = lines.joined(separator: " ")
    if let attributed = parseInlineFormatting(text) {
      blocks.append(.paragraph(attributed))
    }
    lines = []
  }

  /// Parses inline markdown formatting (bold, italic) into AttributedString.
  ///
  /// Uses Swift's native AttributedString markdown parsing which handles
  /// inline formatting correctly.
  ///
  /// - Parameter text: Text potentially containing inline markdown
  /// - Returns: AttributedString with formatting, or nil if parsing fails
  func parseInlineFormatting(_ text: String) -> AttributedString? {
    // Try to parse as markdown for inline formatting
    if let attributed = try? AttributedString(markdown: text) {
      return attributed
    }
    // Fallback to plain text
    return AttributedString(text)
  }
}
