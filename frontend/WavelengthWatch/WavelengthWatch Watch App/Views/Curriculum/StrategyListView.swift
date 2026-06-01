import SwiftUI

struct StrategyListView: View {
  let phase: CatalogPhaseModel
  let color: Color
  @EnvironmentObject private var viewModel: ContentViewModel
  @EnvironmentObject private var presentationCoordinator: PresentationCoordinator
  @Environment(\.isShowingDetailView) private var isShowingDetailView

  /// For strategies-only phases, find a curriculum ID from any available layer/phase
  private var fallbackCurriculumID: Int? {
    // First try the current phase
    if let id = phase.medicinal.first?.id ?? phase.toxic.first?.id {
      return id
    }

    // For strategies-only layers (layer 0), find any curriculum entry from other layers
    // This allows logging strategies against the first available curriculum entry
    for layer in viewModel.layers {
      if layer.id != 0 { // Skip the strategies layer itself
        for layerPhase in layer.phases {
          if let id = layerPhase.medicinal.first?.id ?? layerPhase.toxic.first?.id {
            return id
          }
        }
      }
    }

    return nil
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 4) {
        Text(phase.name)
          .font(.title2)
          .fontWeight(.thin)
          .foregroundColor(.white)
          .padding(.top, 8)
          .padding(.bottom, 12)

        LazyVStack(spacing: 8) {
          ForEach(phase.strategies) { item in
            ZStack(alignment: .topTrailing) {
              HStack {
                Circle()
                  .fill(Color(stage: item.color))
                  .frame(width: 6, height: 6)
                  .shadow(color: Color(stage: item.color), radius: 2)
                Text(item.strategy)
                  .font(.body)
                  .foregroundColor(.white)
                  .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 24)
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 10)
              .background(
                RoundedRectangle(cornerRadius: WLSpacingTokens.cardCornerRadiusSmall)
                  .fill(color.opacity(0.1))
              )
              .onTapGesture {
                if fallbackCurriculumID != nil {
                  presentationCoordinator.request(logRequest(for: item))
                }
              }

              if fallbackCurriculumID != nil {
                MysticalJournalIcon(color: color)
                  .padding(.top, 8)
                  .padding(.trailing, 12)
                  .onTapGesture {
                    presentationCoordinator.request(logRequest(for: item))
                  }
              }
            }
            // Tapped via onTapGesture; expose each row as one labeled VoiceOver
            // element. Only advertise the button trait / action when a tap
            // would log something, so VoiceOver never announces a dead button.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Strategy: \(item.strategy)")
            .accessibilityAddTraits(fallbackCurriculumID != nil ? .isButton : [])
            .accessibilityHint(fallbackCurriculumID != nil ? "Logs this strategy" : "")
            .accessibilityAction {
              guard fallbackCurriculumID != nil else { return }
              presentationCoordinator.request(logRequest(for: item))
            }
          }
        }
        .padding(.horizontal, 8)
      }
      .padding(.vertical, 16)
    }
    .background(WLColorTokens.pageBackground())
    .onAppear {
      isShowingDetailView.wrappedValue = true
    }
    .onDisappear {
      isShowingDetailView.wrappedValue = false
    }
  }

  /// The confirmation request for a tapped strategy row; the root host
  /// renders it and `LogConfirmationHandler` performs the same branching
  /// the view's former `handleLogAction` did.
  private func logRequest(for strategy: CatalogStrategyModel) -> PresentationCoordinator.ActivePresentation {
    .logConfirmation(LogConfirmationRequest(
      alertTitle: "Log Strategy",
      message: "Would you like to log \"\(strategy.strategy)\"?",
      action: .strategy(strategy: strategy, curriculumID: fallbackCurriculumID)
    ))
  }
}
