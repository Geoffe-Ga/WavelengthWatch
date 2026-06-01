import SwiftUI

struct CurriculumCard: View {
  let title: String
  let expression: String
  let accent: Color
  let actionTitle: String
  let entry: CatalogCurriculumEntryModel
  @EnvironmentObject private var presentationCoordinator: PresentationCoordinator

  var body: some View {
    ZStack(alignment: .topTrailing) {
      VStack(alignment: .leading, spacing: 8) {
        Text(title)
          .font(WLTypographyTokens.sectionHeader)
          .fontWeight(WLTypographyTokens.sectionHeaderWeight)
          .foregroundColor(WLColorTokens.secondaryText)
          .tracking(WLTypographyTokens.sectionHeaderTracking)

        Text(expression)
          .font(.body)
          .fontWeight(.medium)
          .foregroundColor(accent)
          .padding(.trailing, 20)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .wlCardSurface(
        WLColorTokens.cardGradient(accent),
        cornerRadius: WLSpacingTokens.cardCornerRadius,
        stroke: accent.opacity(0.5)
      )
      .onTapGesture {
        presentationCoordinator.request(logRequest)
      }

      MysticalJournalIcon(color: accent)
        .padding(.top, 8)
        .padding(.trailing, 12)
        .onTapGesture {
          presentationCoordinator.request(logRequest)
        }
    }
    // The card is tapped via onTapGesture, which SwiftUI does not expose as a
    // VoiceOver action; present it as one labeled button instead.
    .accessibilityElement(children: .ignore)
    .accessibilityAddTraits(.isButton)
    .accessibilityLabel("\(title): \(expression)")
    .accessibilityHint("Logs this entry")
    .accessibilityAction { presentationCoordinator.request(logRequest) }
  }

  /// The confirmation request this card surfaces; the root host renders it
  /// and `LogConfirmationHandler` performs the same branching the card's
  /// former `handleLogAction` did.
  private var logRequest: PresentationCoordinator.ActivePresentation {
    .logConfirmation(LogConfirmationRequest(
      alertTitle: "Log \(title.capitalized)",
      message: "Would you like to log \"\(expression)\"?",
      action: .curriculum(entry: entry)
    ))
  }
}
