import Testing
@testable import WavelengthWatch_Watch_App

/// Pins the single-source-of-truth mapping from a flow step to its navigation +
/// review-sheet reaction (#428). This is the behaviour the two former
/// `onChange(currentStep)` observers split between them, now in one tested place.
struct FlowStepReactionPolicyTests {
  // MARK: - Pop-to-root

  @Test("selecting steps and idle pop the navigation stack to root")
  func selectingAndIdle_popToRoot() {
    for step in [
      FlowCoordinator.FlowStep.selectingPrimary,
      .selectingSecondary,
      .selectingStrategy,
      .idle,
    ] {
      #expect(FlowStepReactionPolicy.reaction(for: step).popsToRoot)
    }
  }

  @Test("confirming and review steps do not pop")
  func confirmingAndReview_doNotPop() {
    for step in [
      FlowCoordinator.FlowStep.confirmingPrimary,
      .confirmingSecondary,
      .confirmingStrategy,
      .review,
    ] {
      #expect(!FlowStepReactionPolicy.reaction(for: step).popsToRoot)
    }
  }

  // MARK: - Review sheet

  @Test("the review step presents the review sheet")
  func reviewStep_presentsSheet() {
    #expect(FlowStepReactionPolicy.reaction(for: .review).reviewSheet == .present)
  }

  @Test("every non-review step dismisses the review sheet only if active")
  func nonReviewSteps_dismissIfActive() {
    for step in [
      FlowCoordinator.FlowStep.idle,
      .selectingPrimary,
      .confirmingPrimary,
      .selectingSecondary,
      .confirmingSecondary,
      .selectingStrategy,
      .confirmingStrategy,
    ] {
      #expect(FlowStepReactionPolicy.reaction(for: step).reviewSheet == .dismissIfActive)
    }
  }

  // MARK: - Combined

  @Test("review presents the sheet without popping; idle pops and dismisses")
  func combinedReactions() {
    #expect(
      FlowStepReactionPolicy.reaction(for: .review)
        == FlowStepReaction(popsToRoot: false, reviewSheet: .present)
    )
    #expect(
      FlowStepReactionPolicy.reaction(for: .idle)
        == FlowStepReaction(popsToRoot: true, reviewSheet: .dismissIfActive)
    )
  }
}
