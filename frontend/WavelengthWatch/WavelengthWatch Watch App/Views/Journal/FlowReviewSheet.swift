import SwiftUI

struct FlowReviewSheet: View {
  @ObservedObject var flowCoordinator: FlowCoordinator
  @State private var isSubmitting = false
  @State private var showingSuccess = false
  @State private var showingError = false
  @State private var errorMessage = ""
  @State private var submitTask: Task<Void, Never>?

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          Text("Review Your Entry")
            .font(.title3)
            .fontWeight(.semibold)
            .padding(.top)

          if let primary = flowCoordinator.selections.primary {
            emotionCard(
              label: "Primary Emotion",
              expression: primary.expression,
              dosage: primary.dosage
            )
          }

          if let secondary = flowCoordinator.selections.secondary {
            emotionCard(
              label: "Secondary Emotion",
              expression: secondary.expression,
              dosage: secondary.dosage
            )
          }

          if let strategy = flowCoordinator.selections.strategy {
            strategyCard(strategy: strategy)
          }

          // Submit button with celebratory gradient styling (fixes #160)
          Button {
            submitEntry()
          } label: {
            if isSubmitting {
              ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
            } else {
              Text("Submit Entry")
                .font(.body)
                .fontWeight(.semibold)
            }
          }
          .disabled(isSubmitting)
          .buttonStyle(.borderedProminent)
          .tint(
            LinearGradient(
              colors: isSubmitting
                ? [Color.gray.opacity(0.6), Color.gray.opacity(0.4)]
                : [Color.blue.opacity(0.8), Color.purple.opacity(0.6), Color.indigo.opacity(0.7)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(maxWidth: .infinity)
        }
        .padding()
      }
      .navigationTitle("Review")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            flowCoordinator.cancel()
          }
          .disabled(isSubmitting)
        }
      }
      .alert("Success", isPresented: $showingSuccess) {
        Button("OK") {
          flowCoordinator.cancel()
        }
      } message: {
        Text("Your journal entry has been saved.")
      }
      .alert("Error", isPresented: $showingError) {
        Button("Retry") {
          submitEntry()
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text(errorMessage)
      }
      // Prevent cancel() racing a still-pending submit Task writing @State after dismiss.
      .interactiveDismissDisabled(isSubmitting)
      // Any transition off .review (toolbar Cancel, success-alert OK, or
      // the system swipe-dismiss binding) means the user backed out — drop
      // the in-flight submit so a hung request can't strand isSubmitting.
      .onChange(of: flowCoordinator.currentStep) { _, newStep in
        if newStep != .review {
          submitTask?.cancel()
        }
      }
    }
  }

  private func emotionCard(label: String, expression: String, dosage: CatalogDosage) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      // Label
      Text(label)
        .font(.caption)
        .foregroundColor(.secondary)
        .textCase(.uppercase)
        .tracking(1.2)

      // Expression (main content)
      Text(expression)
        .font(.body)
        .fontWeight(.bold)
        .lineLimit(nil)

      // Dosage tag underneath (fixes #159: increased circle size for visibility)
      HStack(spacing: 6) {
        Circle()
          .fill(dosage == .medicinal ? Color.green : Color.red)
          .frame(width: 10, height: 10)

        Text(dosage == .medicinal ? "Medicinal" : "Toxic")
          .font(.caption2)
          .foregroundColor(.secondary)
          .textCase(.uppercase)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(WLColorTokens.cardFill)
    )
  }

  private func strategyCard(strategy: CatalogStrategyModel) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Strategy")
        .font(.caption)
        .foregroundColor(.secondary)
        .textCase(.uppercase)

      HStack {
        Circle()
          .fill(Color(stage: strategy.color))
          .frame(width: 10, height: 10)

        Text(strategy.strategy)
          .font(.body)
          .fontWeight(.medium)

        Spacer()
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(WLColorTokens.elevatedCardFill)
    .cornerRadius(10)
  }

  @MainActor
  private func submitEntry() {
    isSubmitting = true
    submitTask = Task {
      do {
        try await SubmitTimeout.run(seconds: SubmitTimeout.journalSubmitDeadlineSeconds) {
          try await flowCoordinator.submit()
        }
        isSubmitting = false
        showingSuccess = true
      } catch JournalError.queuedForRetry {
        // Entry is saved locally and will sync automatically once connectivity
        // is restored. Treat this as a successful submission for UX purposes.
        isSubmitting = false
        showingSuccess = true
      } catch is CancellationError {
        // The flow was cancelled out from under the submit; the sheet is
        // already going away, so reset state without surfacing an error.
        isSubmitting = false
      } catch is SubmitTimeoutError {
        isSubmitting = false
        errorMessage = "Submission timed out. Check your connection and try again."
        showingError = true
      } catch {
        isSubmitting = false
        errorMessage = "Failed to submit: \(error.localizedDescription)"
        showingError = true
      }
    }
  }
}
