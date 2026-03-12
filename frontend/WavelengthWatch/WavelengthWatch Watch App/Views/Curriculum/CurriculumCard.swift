import SwiftUI

struct CurriculumCard: View {
  let title: String
  let expression: String
  let accent: Color
  let actionTitle: String
  let entry: CatalogCurriculumEntryModel
  @EnvironmentObject private var viewModel: ContentViewModel
  @EnvironmentObject private var flowCoordinator: FlowCoordinator
  @State private var showingJournalConfirmation = false

  var body: some View {
    ZStack(alignment: .topTrailing) {
      VStack(alignment: .leading, spacing: 8) {
        Text(title)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(.white.opacity(0.7))
          .tracking(1.5)

        Text(expression)
          .font(.body)
          .fontWeight(.medium)
          .foregroundColor(accent)
          .padding(.trailing, 20)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(
            LinearGradient(
              gradient: Gradient(colors: [accent.opacity(0.3), accent.opacity(0.1)]),
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(accent.opacity(0.5), lineWidth: 0.5)
          )
      )
      .onTapGesture {
        showingJournalConfirmation = true
      }

      MysticalJournalIcon(color: accent)
        .padding(.top, 8)
        .padding(.trailing, 12)
        .onTapGesture {
          showingJournalConfirmation = true
        }
    }
    .alert("Log \(title.capitalized)", isPresented: $showingJournalConfirmation) {
      Button("Yes") {
        handleLogAction()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Would you like to log \"\(expression)\"?")
    }
  }

  private func handleLogAction() {
    switch flowCoordinator.currentStep {
    case .selectingPrimary:
      flowCoordinator.capturePrimary(entry)
    case .selectingSecondary:
      flowCoordinator.captureSecondary(entry)
    case .idle:
      // Auto-start flow when logging from normal mode
      flowCoordinator.startPrimarySelection()
      flowCoordinator.capturePrimary(entry)
    default:
      // Other states (confirming, review, selectingStrategy): immediate logging
      Task { await viewModel.journal(curriculumID: entry.id) }
    }
  }
}
