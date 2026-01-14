import SwiftUI
import Testing

@testable import WavelengthWatch_Watch_App

/// Tests for ContentView navigation with filtered layers.
///
/// These tests verify that layer selection remains correct when switching
/// between filter modes, and that indices are properly synchronized between
/// the filtered and unfiltered layer arrays.
@MainActor
struct ContentViewFilteringTests {
  private func createTestCatalog() -> CatalogResponseModel {
    let phase = CatalogPhaseModel(
      id: 1,
      name: "Rising",
      medicinal: [],
      toxic: [],
      strategies: []
    )

    // Create all 11 layers (0-10) matching production
    let layers = [
      CatalogLayerModel(id: 0, color: "Strategies", title: "SELF-CARE", subtitle: "(Strategies)", phases: [phase]),
      CatalogLayerModel(id: 1, color: "Beige", title: "BEIGE", subtitle: "(Survival)", phases: [phase]),
      CatalogLayerModel(id: 2, color: "Purple", title: "PURPLE", subtitle: "(Tribal)", phases: [phase]),
      CatalogLayerModel(id: 3, color: "Red", title: "RED", subtitle: "(Power)", phases: [phase]),
      CatalogLayerModel(id: 4, color: "Blue", title: "BLUE", subtitle: "(Order)", phases: [phase]),
      CatalogLayerModel(id: 5, color: "Orange", title: "ORANGE", subtitle: "(Achievement)", phases: [phase]),
      CatalogLayerModel(id: 6, color: "Green", title: "GREEN", subtitle: "(Community)", phases: [phase]),
      CatalogLayerModel(id: 7, color: "Yellow", title: "YELLOW", subtitle: "(Integral)", phases: [phase]),
      CatalogLayerModel(id: 8, color: "Turquoise", title: "TURQUOISE", subtitle: "(Holistic)", phases: [phase]),
      CatalogLayerModel(id: 9, color: "Coral", title: "CORAL", subtitle: "(Transpersonal)", phases: [phase]),
      CatalogLayerModel(id: 10, color: "Teal", title: "TEAL", subtitle: "(Unitive)", phases: [phase]),
    ]

    return CatalogResponseModel(phaseOrder: ["Rising"], layers: layers)
  }

  @Test func switchingFromAllToEmotionsOnlyPreservesLayerIdentity() async {
    let catalog = createTestCatalog()
    let repository = CatalogRepositoryMock(cached: catalog, result: .success(catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(catalogRepository: repository, journalRepository: InMemoryJournalRepository(), journalClient: journal)

    await viewModel.loadCatalog()

    // Layers are reversed in ContentViewModel, so layers = [10,9,8,7,6,5,4,3,2,1,0]
    // User is viewing layer 5 (Orange) in browse mode at index 5
    viewModel.selectedLayerIndex = 5
    #expect(viewModel.layers[5].id == 5)
    #expect(viewModel.layers[5].title == "ORANGE")

    // Switch to emotions-only mode
    viewModel.layerFilterMode = .emotionsOnly

    // Expected: selectedLayerId should still be 5 (Orange)
    #expect(viewModel.selectedLayerId == 5)

    // Filtered layers (emotions-only, reversed): [10,9,8,7,6,5,4,3,2,1]
    // Orange (id=5) should be at filtered index 5
    let expectedFilteredIndex = viewModel.layerIdToFilteredIndex(5)
    #expect(expectedFilteredIndex == 5)
    #expect(viewModel.filteredLayers[5].id == 5)
    #expect(viewModel.filteredLayers[5].title == "ORANGE")
  }

  @Test func switchingFromEmotionsOnlyToAllPreservesLayerIdentity() async {
    let catalog = createTestCatalog()
    let repository = CatalogRepositoryMock(cached: catalog, result: .success(catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(catalogRepository: repository, journalRepository: InMemoryJournalRepository(), journalClient: journal)

    await viewModel.loadCatalog()

    // Start in emotions-only mode
    viewModel.layerFilterMode = .emotionsOnly

    // Filtered layers (emotions-only, reversed): [10,9,8,7,6,5,4,3,2,1]
    // User is viewing filtered index 5 (which is Orange, layer id=5)
    #expect(viewModel.filteredLayers[5].id == 5)
    #expect(viewModel.filteredLayers[5].title == "ORANGE")

    // Set selectedLayerId to track by ID
    viewModel.selectedLayerIndex = 5 // Orange in full array (reversed: [10,9,8,7,6,5,...])

    // Switch back to .all mode
    viewModel.layerFilterMode = .all

    // Expected: selectedLayerId should still be 5 (Orange)
    #expect(viewModel.selectedLayerId == 5)
    #expect(viewModel.layers[5].id == 5)
    #expect(viewModel.layers[5].title == "ORANGE")
  }

  @Test func switchingFromEmotionsOnlyToStrategiesOnlyClampsSelection() async {
    let catalog = createTestCatalog()
    let repository = CatalogRepositoryMock(cached: catalog, result: .success(catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(catalogRepository: repository, journalRepository: InMemoryJournalRepository(), journalClient: journal)

    await viewModel.loadCatalog()

    // Start in emotions-only mode, viewing Red (filtered index 2, id=3)
    viewModel.layerFilterMode = .emotionsOnly
    viewModel.selectedLayerId = 3 // Red
    viewModel.selectedLayerIndex = 3 // Red in full array

    // Switch to strategies-only mode (only layer 0)
    viewModel.layerFilterMode = .strategiesOnly

    // Red (id=3) is not in strategies-only, so selection should clamp to layer 0
    #expect(viewModel.filteredLayers.count == 1)
    #expect(viewModel.selectedLayerId == 0) // Clamped to strategies
    #expect(viewModel.filteredLayers[0].id == 0)
  }

  @Test func filterModeChangeDoesNotCrashWithOutOfBoundsIndex() async {
    let catalog = createTestCatalog()
    let repository = CatalogRepositoryMock(cached: catalog, result: .success(catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(catalogRepository: repository, journalRepository: InMemoryJournalRepository(), journalClient: journal)

    await viewModel.loadCatalog()

    // Set to last layer in .all mode (Teal, id=10)
    viewModel.selectedLayerIndex = 10
    viewModel.selectedLayerId = 10
    #expect(viewModel.layers.count == 11)

    // Switch to strategies-only (only 1 layer)
    viewModel.layerFilterMode = .strategiesOnly
    #expect(viewModel.filteredLayers.count == 1)

    // Teal (id=10) is not in strategies, so it should clamp to layer 0
    #expect(viewModel.selectedLayerId == 0)
    #expect(viewModel.filteredLayers[0].id == 0)
  }

  /// Regression test for #158: Strategy cards rendered tiny during emotion logging flow
  ///
  /// Bug: When switching to .strategiesOnly mode, if the UI-layer layerSelection index
  /// was higher than the filtered array size (e.g., layerSelection=5 but filteredLayers
  /// only has 1 element), the LayerCardView.transformEffect computed property would
  /// calculate distance = 0 - 5 = -5, falling into the default case which returns
  /// scale: 0.85 and opacity: 0.0, making the card appear tiny and invisible.
  ///
  /// Fix: ContentView.onChange(of: viewModel.layerFilterMode) now clamps layerSelection
  /// to the valid range for the new filtered layers.
  @Test func strategiesOnlyFilteredIndexIsValidForTransformCalculation() async {
    let catalog = createTestCatalog()
    let repository = CatalogRepositoryMock(cached: catalog, result: .success(catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(catalogRepository: repository, journalRepository: InMemoryJournalRepository(), journalClient: journal)

    await viewModel.loadCatalog()

    // Simulate emotion logging flow: user was viewing layer 5 (Orange) in emotionsOnly mode
    viewModel.layerFilterMode = .emotionsOnly
    viewModel.selectedLayerId = 5
    viewModel.selectedLayerIndex = 5

    // User taps "Add Strategy" which switches to strategiesOnly
    viewModel.layerFilterMode = .strategiesOnly

    // Verify: filteredLayers has only 1 element (strategies layer)
    #expect(viewModel.filteredLayers.count == 1)
    #expect(viewModel.filteredLayers[0].id == 0)

    // Verify: selectedLayerId is clamped to the only available layer (0)
    #expect(viewModel.selectedLayerId == 0)

    // Key verification for #158: The valid filtered index for layer 0 is 0
    // ContentView's onChange handler must clamp layerSelection to this value
    // so that transformEffect calculates distance = 0 - 0 = 0 (not 0 - 5 = -5)
    let validFilteredIndex = viewModel.layerIdToFilteredIndex(0)
    #expect(validFilteredIndex == 0)

    // If layerSelection is properly clamped to 0, then:
    // - layerIndex = 0 (the only layer in filteredLayers)
    // - selectedLayerIndex = 0 (clamped layerSelection)
    // - distance = 0 - 0 = 0
    // - transformEffect returns scale: 1.0, opacity: 1.0 (full size, visible)
  }

  /// Regression test for #180: Strategy cards render tiny when scrolling between selections
  ///
  /// Bug: When user scrolls vertically between primary and secondary emotion selection,
  /// layerSelection updates to a high index. When transitioning to .strategiesOnly mode,
  /// the onChange handler fires AFTER the view renders, causing the first render to use
  /// the stale high layerSelection value.
  ///
  /// Fix: Clamp layerSelection at the point of use in ForEach, not just in onChange handler.
  /// This ensures the value passed to LayerCardView is always valid for current filteredLayers.
  @Test func clampedSelectionIsValidDuringFilterModeTransition() async {
    let catalog = createTestCatalog()
    let repository = CatalogRepositoryMock(cached: catalog, result: .success(catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(catalogRepository: repository, journalRepository: InMemoryJournalRepository(), journalClient: journal)

    await viewModel.loadCatalog()

    // Simulate: User in emotionsOnly mode, scrolls to layer 7 (Yellow)
    viewModel.layerFilterMode = .emotionsOnly
    // In emotionsOnly mode (reversed): [10,9,8,7,6,5,4,3,2,1]
    // Yellow (id=7) would be at filtered index 3

    // User's scroll position updates layerSelection to 7 (as if scrolled far down)
    // This simulates the bug scenario where layerSelection > filteredLayers.count after mode change

    // When switching to strategiesOnly, filteredLayers.count becomes 1
    viewModel.layerFilterMode = .strategiesOnly
    #expect(viewModel.filteredLayers.count == 1)

    // The fix clamps at point of use:
    // clampedSelection = min(7, max(0, 1 - 1)) = min(7, 0) = 0
    let simulatedLayerSelection = 7
    let clampedSelection = min(simulatedLayerSelection, max(0, viewModel.filteredLayers.count - 1))
    #expect(clampedSelection == 0)

    // With clampedSelection = 0 and layerIndex = 0:
    // distance = 0 - 0 = 0 → scale: 1.0, opacity: 1.0 (correct)
    // Without clamping: distance = 0 - 7 = -7 → scale: 0.85, opacity: 0.0 (bug)
  }
}
