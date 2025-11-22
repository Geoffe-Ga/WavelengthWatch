import SwiftUI

/// Prompt view asking whether to add a secondary emotion or skip to strategies.
///
/// This view displays after primary emotion selection and offers two paths:
/// 1. Add Secondary - transitions to secondary emotion selection
/// 2. Skip - advances to strategy selection
@MainActor
struct SecondaryEmotionPromptView: View {
  @ObservedObject var flowViewModel: JournalFlowViewModel
  let onAddSecondary: () -> Void

  var body: some View {
    VStack(spacing: 20) {
      // Title
      Text("Add another emotion?")
        .font(.title3)
        .fontWeight(.medium)
        .multilineTextAlignment(.center)
        .padding(.top)

      // Show primary emotion selected
      if let primaryCurriculum = flowViewModel.getPrimaryCurriculum() {
        VStack(spacing: 8) {
          Text("Primary emotion:")
            .font(.caption)
            .foregroundColor(.secondary)
            .textCase(.uppercase)

          Text(primaryCurriculum.expression)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(primaryCurriculum.dosage == .medicinal ? .green : .red)
        }
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(Color.secondary.opacity(0.1))
        )
      }

      Spacer()

      // Action buttons
      VStack(spacing: 12) {
        // Add Secondary button - triggers transition to selection UI
        Button {
          onAddSecondary()
        } label: {
          Text("Add Secondary")
            .font(.body)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)

        // Skip button - advance to strategy selection
        Button {
          flowViewModel.advanceStep()
        } label: {
          Text("Skip")
            .font(.body)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.secondary.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal)
      .padding(.bottom)
    }
  }
}

// MARK: - Previews

#Preview {
  let catalog = CatalogResponseModel(
    phaseOrder: ["Rising"],
    layers: [
      CatalogLayerModel(
        id: 3,
        color: "Red",
        title: "RED",
        subtitle: "(Power)",
        phases: [
          CatalogPhaseModel(
            id: 1,
            name: "Rising",
            medicinal: [
              CatalogCurriculumEntryModel(id: 1, dosage: .medicinal, expression: "Confident"),
            ],
            toxic: [
              CatalogCurriculumEntryModel(id: 2, dosage: .toxic, expression: "Aggressive"),
            ],
            strategies: []
          ),
        ]
      ),
    ]
  )

  let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)
  viewModel.selectPrimaryCurriculum(id: 1)
  viewModel.advanceStep()

  return SecondaryEmotionPromptView(
    flowViewModel: viewModel,
    onAddSecondary: {
      print("Add Secondary tapped")
    }
  )
}
