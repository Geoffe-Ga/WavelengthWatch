import SwiftUI

/// A view that renders parsed markdown blocks with proper watchOS formatting.
///
/// This view solves the problem of SwiftUI's Text not rendering block-level
/// AttributedString formatting (lists, paragraph breaks, headers) on watchOS.
/// Instead of relying on AttributedString presentation intents, it renders
/// each block type with explicit SwiftUI styling.
struct MarkdownContentView: View {
  let blocks: [MarkdownBlock]

  /// Spacing between major sections (headers and their content)
  private let sectionSpacing: CGFloat = 16

  /// Spacing between paragraphs within a section
  private let paragraphSpacing: CGFloat = 12

  /// Spacing between list items
  private let listItemSpacing: CGFloat = 6

  var body: some View {
    VStack(alignment: .leading, spacing: paragraphSpacing) {
      ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
        blockView(for: block, at: index)
      }
    }
  }

  @ViewBuilder
  private func blockView(for block: MarkdownBlock, at index: Int) -> some View {
    switch block {
    case let .header1(text):
      Text(text)
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.white)
        .padding(.top, index > 0 ? sectionSpacing : 0)

    case let .header2(text):
      Text(text)
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundColor(.white)
        .padding(.top, index > 0 ? sectionSpacing : 0)

    case let .header3(text):
      Text(text)
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(.white.opacity(0.9))
        .padding(.top, index > 0 ? paragraphSpacing : 0)

    case let .paragraph(attributed):
      Text(attributed)
        .font(.body)
        .foregroundColor(.white.opacity(0.85))
        .fixedSize(horizontal: false, vertical: true)

    case let .listItem(attributed):
      HStack(alignment: .top, spacing: 8) {
        Text("\u{2022}")
          .font(.body)
          .foregroundColor(.white.opacity(0.6))

        Text(attributed)
          .font(.body)
          .foregroundColor(.white.opacity(0.85))
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(.leading, 4)

    case let .blockquote(attributed):
      HStack(alignment: .top, spacing: 8) {
        Rectangle()
          .fill(Color.white.opacity(0.3))
          .frame(width: 2)

        Text(attributed)
          .font(.body)
          .italic()
          .foregroundColor(.white.opacity(0.75))
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(.vertical, 4)

    case .empty:
      EmptyView()
    }
  }
}

// MARK: - Preview

#if DEBUG
#Preview("Markdown Content") {
  ScrollView {
    MarkdownContentView(blocks: [
      .header1("Main Title"),
      .paragraph(AttributedString("This is a paragraph with some text.")),
      .header2("Section Header"),
      .paragraph(try! AttributedString(markdown: "This has **bold** and *italic* text.")),
      .listItem(try! AttributedString(markdown: "**First** item")),
      .listItem(AttributedString("Second item")),
      .listItem(AttributedString("Third item")),
      .blockquote(AttributedString("This is a quote")),
    ])
    .padding()
  }
  .background(Color.black)
}
#endif
