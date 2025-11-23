import SwiftUI

/// Review screen showing all user selections before journal submission.
///
/// Displays primary emotion, optional secondary emotion, optional strategy,
/// and timestamp. Provides submit button to create journal entry via backend.
@MainActor
struct JournalReviewView: View {
  let catalog: CatalogResponseModel
  @ObservedObject var flowViewModel: JournalFlowViewModel
  let journalClient: JournalClientProtocol
  let onSuccess: () -> Void
  let onEdit: () -> Void

  @State private var isSubmitting: Bool = false
  @State private var showingSuccessAlert: Bool = false
  @State private var showingErrorAlert: Bool = false
  @State private var errorMessage: String = ""
  @State private var submitTask: Task<Void, Never>?

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        // Title
        Text("Review Your Entry")
          .font(.title3)
          .fontWeight(.semibold)
          .padding(.top)

        // Timestamp
        VStack(spacing: 4) {
          Text("Logged At")
            .font(.caption)
            .foregroundColor(.secondary)
            .textCase(.uppercase)

          Text(formattedTimestamp)
            .font(.body)
            .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)

        Divider()

        // Primary emotion
        if let primary = flowViewModel.getPrimaryCurriculum() {
          emotionCard(
            label: "Primary Emotion",
            expression: primary.expression,
            dosage: primary.dosage
          )
        }

        // Secondary emotion (if selected)
        if let secondary = flowViewModel.getSecondaryCurriculum() {
          emotionCard(
            label: "Secondary Emotion",
            expression: secondary.expression,
            dosage: secondary.dosage
          )
        }

        // Strategy (if selected)
        if let strategy = flowViewModel.getStrategy() {
          strategyCard(strategy: strategy)
        }

        Divider()

        // Action buttons
        VStack(spacing: 12) {
          Button {
            submitEntry()
          } label: {
            if isSubmitting {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            } else {
              Text("Submit Entry")
                .fontWeight(.semibold)
            }
          }
          .disabled(isSubmitting)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(isSubmitting ? Color.gray : Color.blue)
          .foregroundColor(.white)
          .cornerRadius(10)

          Button {
            onEdit()
          } label: {
            Text("Edit")
              .foregroundColor(.blue)
          }
          .disabled(isSubmitting)
        }
        .padding(.bottom)
      }
      .padding(.horizontal)
    }
    .alert("Success", isPresented: $showingSuccessAlert) {
      Button("OK") {
        onSuccess()
      }
    } message: {
      Text("Your journal entry has been saved.")
    }
    .alert("Error", isPresented: $showingErrorAlert) {
      Button("Retry") {
        submitEntry()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text(errorMessage)
    }
    .onDisappear {
      submitTask?.cancel()
      submitTask = nil
    }
  }

  private var formattedTimestamp: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: Date())
  }

  @ViewBuilder
  private func emotionCard(label: String, expression: String, dosage: CatalogDosage) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(label)
        .font(.caption)
        .foregroundColor(.secondary)
        .textCase(.uppercase)

      HStack {
        Circle()
          .fill(dosage == .medicinal ? Color.green : Color.red)
          .frame(width: 10, height: 10)

        Text(expression)
          .font(.body)
          .fontWeight(.medium)
          .foregroundColor(.primary)

        Spacer()

        Text(dosage == .medicinal ? "Medicinal" : "Toxic")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(Color.secondary.opacity(0.1))
    .cornerRadius(10)
  }

  @ViewBuilder
  private func strategyCard(strategy: CatalogStrategyModel) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Strategy")
        .font(.caption)
        .foregroundColor(.secondary)
        .textCase(.uppercase)

      HStack {
        Circle()
          .fill(colorForStrategy(strategy.color))
          .frame(width: 10, height: 10)

        Text(strategy.strategy)
          .font(.body)
          .fontWeight(.medium)
          .foregroundColor(.primary)

        Spacer()
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(Color.secondary.opacity(0.1))
    .cornerRadius(10)
  }

  private func colorForStrategy(_ colorName: String) -> Color {
    switch colorName.lowercased() {
    case "blue": .blue
    case "cyan": .cyan
    case "green": .green
    case "yellow": .yellow
    case "orange": .orange
    case "red": .red
    case "purple": .purple
    case "pink": .pink
    default: .gray
    }
  }

  private func submitEntry() {
    guard let primaryCurriculumID = flowViewModel.primaryCurriculumID else {
      errorMessage = "Primary emotion is required"
      showingErrorAlert = true
      return
    }

    isSubmitting = true

    submitTask = Task { @MainActor in
      do {
        _ = try await journalClient.submit(
          curriculumID: primaryCurriculumID,
          secondaryCurriculumID: flowViewModel.secondaryCurriculumID,
          strategyID: flowViewModel.strategyID,
          initiatedBy: flowViewModel.initiatedBy
        )

        guard !Task.isCancelled else { return }

        isSubmitting = false
        showingSuccessAlert = true
      } catch {
        guard !Task.isCancelled else { return }

        isSubmitting = false
        errorMessage = "Failed to submit entry: \(error.localizedDescription)"
        showingErrorAlert = true
      }
    }
  }
}

// MARK: - Previews

#Preview {
  let catalog = CatalogResponseModel(
    phaseOrder: ["Rising"],
    layers: [
      CatalogLayerModel(
        id: 0,
        color: "Strategies",
        title: "SELF-CARE",
        subtitle: "(Strategies)",
        phases: [
          CatalogPhaseModel(
            id: 1,
            name: "Rising",
            medicinal: [],
            toxic: [],
            strategies: [
              CatalogStrategyModel(id: 10, strategy: "Deep Breathing", color: "Blue"),
            ]
          ),
        ]
      ),
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
              CatalogCurriculumEntryModel(id: 2, dosage: .toxic, expression: "Anxious"),
            ],
            strategies: []
          ),
        ]
      ),
    ]
  )

  class MockJournalClient: JournalClientProtocol {
    func submit(
      curriculumID: Int,
      secondaryCurriculumID: Int?,
      strategyID: Int?,
      initiatedBy: InitiatedBy
    ) async throws -> JournalResponseModel {
      try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
      return JournalResponseModel(
        id: 1,
        curriculumID: curriculumID,
        secondaryCurriculumID: secondaryCurriculumID,
        strategyID: strategyID,
        initiatedBy: initiatedBy
      )
    }
  }

  let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)
  viewModel.selectPrimaryCurriculum(id: 1)
  viewModel.advanceStep()
  viewModel.advanceStep()
  viewModel.selectStrategy(id: 10)
  viewModel.advanceStep()

  return JournalReviewView(
    catalog: catalog,
    flowViewModel: viewModel,
    journalClient: MockJournalClient(),
    onSuccess: { print("Success") },
    onEdit: { print("Edit") }
  )
}
