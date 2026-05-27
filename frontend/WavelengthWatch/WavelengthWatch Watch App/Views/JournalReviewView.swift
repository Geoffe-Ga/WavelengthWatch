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
        // Title - different for REST entries
        Text(flowViewModel.entryType == .rest ? "Honoring Rest" : "Review Your Entry")
          .font(.title3)
          .fontWeight(.semibold)
          .padding(.top)

        if flowViewModel.entryType == .rest {
          JournalReviewRestHeader()
        }

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
        .background(WLColorTokens.elevatedCardFill)
        .cornerRadius(8)

        Divider()

        // Emotion details - only for EMOTION entries
        if flowViewModel.entryType == .emotion {
          // Primary emotion
          if let primary = flowViewModel.getPrimaryCurriculum() {
            JournalReviewEmotionCard(
              label: "Primary Emotion",
              expression: primary.expression,
              dosage: primary.dosage
            )
          }

          // Secondary emotion (if selected)
          if let secondary = flowViewModel.getSecondaryCurriculum() {
            JournalReviewEmotionCard(
              label: "Secondary Emotion",
              expression: secondary.expression,
              dosage: secondary.dosage
            )
          }

          // Strategy (if selected)
          if let strategy = flowViewModel.getStrategy() {
            JournalReviewStrategyCard(strategy: strategy)
          }

          Divider()
        }

        JournalReviewActions(
          isSubmitting: isSubmitting,
          onSubmit: submitEntry,
          onEdit: onEdit
        )
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
      isSubmitting = false
    }
  }

  private static let timestampFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
  }()

  private var formattedTimestamp: String {
    Self.timestampFormatter.string(from: Date())
  }

  private func submitEntry() {
    isSubmitting = true

    submitTask = Task { @MainActor in
      do {
        if flowViewModel.entryType == .rest {
          // Submit REST entry
          _ = try await journalClient.submitRestPeriod(
            initiatedBy: flowViewModel.initiatedBy
          )
        } else {
          // Submit EMOTION entry
          guard let primaryCurriculumID = flowViewModel.primaryCurriculumID else {
            errorMessage = "Primary emotion is required"
            showingErrorAlert = true
            isSubmitting = false
            return
          }

          _ = try await journalClient.submit(
            curriculumID: primaryCurriculumID,
            secondaryCurriculumID: flowViewModel.secondaryCurriculumID,
            strategyID: flowViewModel.strategyID,
            initiatedBy: flowViewModel.initiatedBy
          )
        }

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
    ) async throws -> LocalJournalEntry {
      try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
      return LocalJournalEntry(
        createdAt: Date(),
        userID: 123,
        curriculumID: curriculumID,
        secondaryCurriculumID: secondaryCurriculumID,
        strategyID: strategyID,
        initiatedBy: initiatedBy,
        entryType: .emotion
      )
    }

    func submitRestPeriod(
      initiatedBy: InitiatedBy
    ) async throws -> LocalJournalEntry {
      try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
      return LocalJournalEntry(
        createdAt: Date(),
        userID: 123,
        curriculumID: nil,
        initiatedBy: initiatedBy,
        entryType: .rest
      )
    }
  }

  let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)
  viewModel.selectEntryType(.emotion)
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
