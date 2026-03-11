import SwiftUI

/// Card for displaying emotions in Clear Light view with source layer color coding
struct ClearLightEmotionCard: View {
  let emotion: LayeredEmotion
  let dosageType: CatalogDosage
  @EnvironmentObject private var viewModel: ContentViewModel
  @EnvironmentObject private var flowCoordinator: FlowCoordinator
  @State private var showingJournalConfirmation = false

  var body: some View {
    ZStack(alignment: .topTrailing) {
      HStack(spacing: 10) {
        // Color indicator for source layer
        Circle()
          .fill(emotion.sourceColor)
          .frame(width: 10, height: 10)
          .shadow(color: emotion.sourceColor, radius: 2)

        VStack(alignment: .leading, spacing: 2) {
          Text(emotion.entry.expression)
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(dosageType == .medicinal ? emotion.sourceColor : .red)

          Text(emotion.layerTitle)
            .font(.caption2)
            .foregroundColor(.white.opacity(0.5))
        }

        Spacer()
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(
            LinearGradient(
              gradient: Gradient(colors: [
                emotion.sourceColor.opacity(0.2),
                emotion.sourceColor.opacity(0.1),
              ]),
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(emotion.sourceColor.opacity(0.3), lineWidth: 0.5)
          )
      )
      .padding(.horizontal, 8)
      .onTapGesture {
        showingJournalConfirmation = true
      }

      MysticalJournalIcon(color: emotion.sourceColor)
        .padding(.top, 8)
        .padding(.trailing, 20)
        .onTapGesture {
          showingJournalConfirmation = true
        }
    }
    .alert("Log \(dosageType == .medicinal ? "Medicinal" : "Toxic")", isPresented: $showingJournalConfirmation) {
      Button("Yes") {
        handleLogAction()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Would you like to log \"\(emotion.entry.expression)\"?")
    }
  }

  private func handleLogAction() {
    switch flowCoordinator.currentStep {
    case .selectingPrimary:
      flowCoordinator.capturePrimary(emotion.entry)
    case .selectingSecondary:
      flowCoordinator.captureSecondary(emotion.entry)
    case .idle:
      // Auto-start flow when logging from normal mode
      flowCoordinator.startPrimarySelection()
      flowCoordinator.capturePrimary(emotion.entry)
    default:
      // Other states: immediate logging
      Task { await viewModel.journal(curriculumID: emotion.entry.id) }
    }
  }
}
