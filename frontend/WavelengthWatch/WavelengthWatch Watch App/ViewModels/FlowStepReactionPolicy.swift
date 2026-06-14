import Foundation

/// What the review sheet should do in response to a flow-step transition.
enum ReviewSheetAction: Equatable {
  /// Present the flow-review sheet.
  case present
  /// Dismiss it, but only if it is the active presentation.
  case dismissIfActive
}

/// The combined navigation + presentation response to a flow-step transition.
/// A read-only value object computed once per transition and consumed
/// immediately, so its fields are immutable.
struct FlowStepReaction: Equatable {
  /// Pop the navigation stack to root so the user isn't stranded in a detail
  /// view across a flow boundary (the #157 / #162 / #164 fix).
  let popsToRoot: Bool
  let reviewSheet: ReviewSheetAction
}

/// Single source of truth for how a `FlowCoordinator.FlowStep` transition maps
/// to navigation pops and review-sheet presentation.
///
/// Previously these two reactions lived in two independent
/// `onChange(currentStep)` observers (`MainContentDialogsModifier` for the pop,
/// `RootPresentationHost` for the sheet), which both fired on every transition
/// and could race on watchOS's single-presentation-per-scene constraint. This
/// pure policy lets exactly one observer apply both in a defined order, and
/// makes the decision unit-testable without rendering a view (#428).
enum FlowStepReactionPolicy {
  /// The navigation + review-sheet reaction for a given flow step.
  static func reaction(for step: FlowCoordinator.FlowStep) -> FlowStepReaction {
    FlowStepReaction(popsToRoot: popsToRoot(step), reviewSheet: reviewSheet(step))
  }

  /// Every step except `.review` pops to root. The **confirming** steps pop
  /// too (#450): the flow-confirmation alert (e.g. "Add Secondary Emotion") is
  /// hosted on the root content, so if the user tapped an emotion inside a
  /// pushed detail view the alert would otherwise wait until they backed out.
  /// Only `.review` stays put — its sheet is presented above the push by
  /// `RootPresentationHost`.
  private static func popsToRoot(_ step: FlowCoordinator.FlowStep) -> Bool {
    switch step {
    case .idle, .selectingPrimary, .selectingSecondary, .selectingStrategy,
         .confirmingPrimary, .confirmingSecondary, .confirmingStrategy:
      true
    case .review:
      false
    }
  }

  private static func reviewSheet(_ step: FlowCoordinator.FlowStep) -> ReviewSheetAction {
    step == .review ? .present : .dismissIfActive
  }
}
