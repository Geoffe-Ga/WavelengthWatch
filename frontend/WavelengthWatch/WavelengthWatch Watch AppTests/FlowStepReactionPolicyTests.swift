import Testing
@testable import WavelengthWatch_Watch_App

/// Pins the single-source-of-truth mapping from a flow step to its navigation +
/// review-sheet reaction (#428). This is the behaviour the two former
/// `onChange(currentStep)` observers split between them, now in one tested place.
struct FlowStepReactionPolicyTests {
  // MARK: - Pop-to-root

  // Iterating `allCases` (not a hand-listed subset) means a newly added
  // FlowStep is automatically held to the rule, closing the coverage gap.

  @Test("every step pops to root except .review, whose sheet sits above the push")
  func popToRoot_coversEveryStep() {
    for step in FlowCoordinator.FlowStep.allCases {
      let expected = step != .review // confirming steps pop too (#450)
      #expect(FlowStepReactionPolicy.reaction(for: step).popsToRoot == expected)
    }
  }

  // MARK: - Review sheet

  @Test("only .review presents the sheet; every other step dismisses it if active")
  func reviewSheet_coversEveryStep() {
    for step in FlowCoordinator.FlowStep.allCases {
      let expected: ReviewSheetAction = step == .review ? .present : .dismissIfActive
      #expect(FlowStepReactionPolicy.reaction(for: step).reviewSheet == expected)
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
