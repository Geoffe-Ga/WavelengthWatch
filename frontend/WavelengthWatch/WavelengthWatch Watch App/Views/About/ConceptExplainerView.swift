import SwiftUI

struct ConceptExplainerView: View {
  @State private var blocks: [MarkdownBlock]?
  @State private var errorMessage: String?
  private let loader = MarkdownContentLoader()

  var body: some View {
    ScrollView {
      VStack(alignment: .center, spacing: 16) {
        // App icon header
        Image("AboutIcon")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 70, height: 70)
          .clipShape(RoundedRectangle(cornerRadius: 16))
          .padding(.top, 8)

        // Content area
        VStack(alignment: .leading, spacing: 16) {
          if let blocks {
            MarkdownContentView(blocks: blocks)
              .padding(.horizontal)
          } else if let errorMessage {
            // Error state
            VStack(spacing: 12) {
              Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

              Text("Unable to Load Content")
                .font(.headline)

              Text(errorMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
          } else {
            // Loading state
            VStack(spacing: 12) {
              ProgressView()
                .progressViewStyle(.circular)

              Text("Loading...")
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
          }
        }
      }
    }
    .navigationTitle("About")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await loadMarkdown()
    }
  }

  private func loadMarkdown() async {
    let result = await loader.loadParsedContent(fileName: "about-content")

    switch result {
    case let .success(content):
      blocks = content.blocks
    case let .failure(error):
      errorMessage = errorMessageFor(error)
    }
  }

  private func errorMessageFor(_ error: MarkdownLoadError) -> String {
    switch error {
    case .fileNotFound:
      "Content file not found"
    case .readFailed:
      "Unable to read content file"
    case .parsingFailed:
      "Unable to parse content"
    }
  }
}
