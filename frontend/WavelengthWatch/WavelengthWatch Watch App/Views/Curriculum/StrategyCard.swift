import SwiftUI

struct StrategyCard: View {
  let strategy: CatalogStrategyModel
  let color: Color
  let phase: CatalogPhaseModel
  @EnvironmentObject private var flowCoordinator: FlowCoordinator
  @EnvironmentObject private var presentationCoordinator: PresentationCoordinator

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
      .wlCardSurface(
        WLColorTokens.cardFill(tinted: color),
        cornerRadius: WLSpacingTokens.cardCornerRadiusSmall
      )
      .onTapGesture {
        if isActionable {
          presentationCoordinator.request(logRequest)
        }
      }

      if isActionable {
        MysticalJournalIcon(color: color)
          .padding(.top, 6)
          .padding(.trailing, 8)
          .onTapGesture {
            presentationCoordinator.request(logRequest)
          }
      }
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
      presentationCoordinator.request(logRequest)
    }
  }

  /// The confirmation request this card surfaces; the root host renders it
  /// and `LogConfirmationHandler` performs the same branching the card's
  /// former `handleLogAction` did.
  private var logRequest: PresentationCoordinator.ActivePresentation {
    .logConfirmation(LogConfirmationRequest(
      alertTitle: "Log Strategy",
      message: "Would you like to log \"\(strategy.strategy)\"?",
      action: .strategy(strategy: strategy, curriculumID: primaryID)
    ))
  }
}
