import SwiftUI

/// Card for displaying emotions in Clear Light view with source layer color coding.
///
/// Like `CurriculumCard`/`StrategyCard`, this leaf emits a log-confirmation
/// *intent* via `PresentationCoordinator` instead of owning a local `.alert`.
/// The former leaf-local alert was rendered from inside the pushed
/// `CurriculumDetailView`, so it (and its fire-and-forget journal `Task`) was
/// deferred behind the navigation context until the user backed out — B2 in
/// `prompts/claude-comm/spec-primary-selector-rebuild.md`. Routing through the
/// root-anchored `RootPresentationHost` makes it present (and log) immediately.
struct ClearLightEmotionCard: View {
  let emotion: LayeredEmotion
  let dosageType: CatalogDosage
  @EnvironmentObject private var presentationCoordinator: PresentationCoordinator

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
            .foregroundColor(WLColorTokens.tertiaryText)
        }

        Spacer()
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .wlCardSurface(
        LinearGradient(
          gradient: Gradient(colors: [
            emotion.sourceColor.opacity(0.2),
            emotion.sourceColor.opacity(0.1),
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        ),
        cornerRadius: WLSpacingTokens.cardCornerRadius,
        stroke: emotion.sourceColor.opacity(0.3)
      )
      .padding(.horizontal, 8)
      .onTapGesture {
        presentationCoordinator.request(logRequest)
      }

      MysticalJournalIcon(color: emotion.sourceColor)
        .padding(.top, 8)
        .padding(.trailing, 20)
        .onTapGesture {
          presentationCoordinator.request(logRequest)
        }
    }
    // Tapped via onTapGesture; expose as one labeled VoiceOver button.
    .accessibilityElement(children: .ignore)
    .accessibilityAddTraits(.isButton)
    .accessibilityLabel("\(dosageLabel): \(emotion.entry.expression), \(emotion.layerTitle)")
    .accessibilityHint("Logs this entry")
    .accessibilityAction { presentationCoordinator.request(logRequest) }
  }

  /// Human-readable dosage label used in the alert title and accessibility copy.
  private var dosageLabel: String {
    dosageType == .medicinal ? "Medicinal" : "Toxic"
  }

  /// The confirmation request this card surfaces; the root host renders it and
  /// `LogConfirmationHandler` performs the same branching the card's former
  /// `handleLogAction` did (capture into the flow when selecting, log directly
  /// otherwise).
  var logRequest: PresentationCoordinator.ActivePresentation {
    .logConfirmation(LogConfirmationRequest(
      alertTitle: "Log \(dosageLabel)",
      message: "Would you like to log \"\(emotion.entry.expression)\"?",
      action: .curriculum(entry: emotion.entry)
    ))
  }
}
