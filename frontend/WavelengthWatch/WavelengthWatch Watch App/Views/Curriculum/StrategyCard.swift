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

  /// Whether tapping logs anything: either a curriculum entry exists to log
  /// the strategy against, or we're inside the strategy-selection flow.
  private var isActionable: Bool {
    primaryID != nil || flowCoordinator.currentStep == .selectingStrategy
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
        if isActionable {
          showingJournalConfirmation = true
        }
      }

      if isActionable {
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
    // Tapped via onTapGesture; expose as one labeled VoiceOver element. Only
    // advertise the button trait / action when a tap would actually log
    // something, so VoiceOver never announces a dead button.
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Strategy: \(strategy.strategy)")
    .accessibilityAddTraits(isActionable ? .isButton : [])
    .accessibilityHint(isActionable ? "Logs this strategy" : "")
    .accessibilityAction {
      guard isActionable else { return }
      showingJournalConfirmation = true
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
