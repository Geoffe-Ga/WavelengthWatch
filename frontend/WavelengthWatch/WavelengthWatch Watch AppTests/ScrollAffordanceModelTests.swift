import Testing
@testable import WavelengthWatch_Watch_App

/// Tests for `ScrollAffordanceModel`'s edge math and interaction state
/// (#410). The vertical layer axis is clamped (edge-aware up/down); the
/// horizontal phase axis wraps infinitely (left/right available whenever
/// more than one phase exists).
@MainActor
struct ScrollAffordanceModelTests {
  @Test("first layer suppresses up, allows down")
  func firstLayer() {
    let model = ScrollAffordanceModel()
    model.update(layerSelection: 0, layerCount: 5, phaseCount: 6)

    #expect(model.affordances.canGoUp == false)
    #expect(model.affordances.canGoDown == true)
  }

  @Test("last layer suppresses down, allows up")
  func lastLayer() {
    let model = ScrollAffordanceModel()
    model.update(layerSelection: 4, layerCount: 5, phaseCount: 6)

    #expect(model.affordances.canGoUp == true)
    #expect(model.affordances.canGoDown == false)
  }

  @Test("a middle layer allows both up and down")
  func middleLayer() {
    let model = ScrollAffordanceModel()
    model.update(layerSelection: 2, layerCount: 5, phaseCount: 6)

    #expect(model.affordances.canGoUp == true)
    #expect(model.affordances.canGoDown == true)
  }

  @Test("a single layer suppresses both up and down")
  func singleLayer() {
    let model = ScrollAffordanceModel()
    model.update(layerSelection: 0, layerCount: 1, phaseCount: 6)

    #expect(model.affordances.canGoUp == false)
    #expect(model.affordances.canGoDown == false)
  }

  @Test("multiple phases allow left and right (infinite wrap)")
  func multiplePhases() {
    let model = ScrollAffordanceModel()
    model.update(layerSelection: 2, layerCount: 5, phaseCount: 6)

    #expect(model.affordances.canGoLeft == true)
    #expect(model.affordances.canGoRight == true)
  }

  @Test("a single phase suppresses left and right")
  func singlePhase() {
    let model = ScrollAffordanceModel()
    model.update(layerSelection: 2, layerCount: 5, phaseCount: 1)

    #expect(model.affordances.canGoLeft == false)
    #expect(model.affordances.canGoRight == false)
  }

  @Test("zero layers suppresses both up and down")
  func zeroLayers() {
    let model = ScrollAffordanceModel()
    model.update(layerSelection: 0, layerCount: 0, phaseCount: 3)

    #expect(model.affordances.canGoUp == false)
    #expect(model.affordances.canGoDown == false)
  }

  @Test("zero phases suppresses both left and right")
  func zeroPhases() {
    let model = ScrollAffordanceModel()
    model.update(layerSelection: 2, layerCount: 5, phaseCount: 0)

    #expect(model.affordances.canGoLeft == false)
    #expect(model.affordances.canGoRight == false)
  }

  @Test("isInteracting toggles and ignores redundant writes")
  func interactionTransitions() {
    let model = ScrollAffordanceModel()
    #expect(model.isInteracting == false)

    model.setInteracting(true)
    #expect(model.isInteracting == true)

    model.setInteracting(true) // redundant — no change
    #expect(model.isInteracting == true)

    model.setInteracting(false)
    #expect(model.isInteracting == false)
  }
}
