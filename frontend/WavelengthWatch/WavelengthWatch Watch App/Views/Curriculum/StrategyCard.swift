import SwiftUI

struct StrategyCard: View {
  let strategy: CatalogStrategyModel
  let color: Color
  let phase: CatalogPhaseModel
  @EnvironmentObject private var viewModel: ContentViewModel
  @EnvironmentObject private var flowCoordinator: FlowCoordinator
  @State private var showingJournalConfirmation = false

  private var primaryID: Int? {
    phase.medicinal.first?.id ?? phase.toxic.first?.id
  }

  var body: some View {
    ZStack(alignment: .topTrailing) {
      HStack {
        Circle()
          .fill(Color(stage: strategy.color))
          .frame(width: 6, height: 6)
          .shadow(color: Color(stage: strategy.color), radius: 2)
        Text(strategy.strategy)
          .font(.footnote)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity, alignment: .leading)
        Spacer(minLength: 20)
      }
      .padding(8)
      .background(
        RoundedRectangle(cornerRadius: WLSpacingTokens.cardCornerRadiusSmall)
          .fill(WLColorTokens.cardFill(tinted: color))
      )
      .onTapGesture {
        if primaryID != nil || flowCoordinator.currentStep == .selectingStrategy {
          showingJournalConfirmation = true
        }
      }

      if primaryID != nil || flowCoordinator.currentStep == .selectingStrategy {
        MysticalJournalIcon(color: color)
          .padding(.top, 6)
          .padding(.trailing, 8)
          .onTapGesture {
            showingJournalConfirmation = true
          }
      }
    }
    .alert("Log Strategy", isPresented: $showingJournalConfirmation) {
      Button("Yes") {
        handleLogAction()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Would you like to log \"\(strategy.strategy)\"?")
    }
    // Tapped via onTapGesture; expose as one labeled VoiceOver button whose
    // action mirrors the tap's actionable guard.
    .accessibilityElement(children: .ignore)
    .accessibilityAddTraits(.isButton)
    .accessibilityLabel("Strategy: \(strategy.strategy)")
    .accessibilityHint("Logs this strategy")
    .accessibilityAction {
      if primaryID != nil || flowCoordinator.currentStep == .selectingStrategy {
        showingJournalConfirmation = true
      }
    }
  }

  private func handleLogAction() {
    if flowCoordinator.currentStep == .selectingStrategy {
      flowCoordinator.captureStrategy(strategy)
    } else {
      if let primaryID {
        Task {
          await viewModel.journal(
            curriculumID: primaryID,
            strategyID: strategy.id
          )
        }
      }
    }
  }
}
