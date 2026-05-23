import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

/// Coverage for `NavigationViewModel` — the six reconciliation paths that
/// previously lived in `NavigationSyncModifier` (#329). Each handler is
/// exercised directly so the assertions stay synchronous and deterministic
/// (the Combine wiring that routes model changes into these handlers is
/// integration-level and is verified in the app).
@MainActor
struct NavigationViewModelTests {
  // MARK: - Fixtures

  private func makeViewModel() -> ContentViewModel {
    let catalog = CatalogTestHelper.createTestCatalog()
    return ContentViewModel(
      catalogRepository: CatalogRepositoryMock(cached: catalog, result: .success(catalog)),
      journalRepository: InMemoryJournalRepository(),
      journalClient: JournalClientMock()
    )
  }

  private func makeLayer(_ id: Int) -> CatalogLayerModel {
    CatalogLayerModel(id: id, color: "C\(id)", title: "T\(id)", subtitle: "(s)", phases: [])
  }

  private func freshDefaults() -> UserDefaults {
    UserDefaults(suiteName: "nav-vm-test-\(UUID().uuidString)")!
  }

  private let sixPhases = ["a", "b", "c", "d", "e", "f"]

  // MARK: - Path 2: layerSelection → model

  @Test("a layerSelection change writes the layer ID, full index, and AppStorage")
  func layerSelectionChanged_writesModelAndPersists() {
    let viewModel = makeViewModel()
    viewModel.layers = [makeLayer(0), makeLayer(1), makeLayer(2)]
    let defaults = freshDefaults()
    let nav = NavigationViewModel(
      contentViewModel: viewModel,
      initialLayer: 0,
      initialPhaseSelection: 1,
      userDefaults: defaults
    )

    nav.layerSelection = 2

    #expect(viewModel.selectedLayerId == 2)
    #expect(viewModel.selectedLayerIndex == 2)
    #expect(defaults.integer(forKey: AppStorageKeys.selectedLayerIndex) == 2)
  }

  @Test("layerSelectionChanged is a no-op when the resolved layer ID is already selected")
  func layerSelectionChanged_sameLayerId_isNoOp() {
    let viewModel = makeViewModel()
    viewModel.layers = [makeLayer(0), makeLayer(1), makeLayer(2)]
    viewModel.selectedLayerId = 2
    let defaults = freshDefaults()
    let nav = NavigationViewModel(
      contentViewModel: viewModel,
      initialLayer: 2,
      initialPhaseSelection: 1,
      userDefaults: defaults
    )

    // No value change — didSet fires but the equality guard should
    // short-circuit before any model or UserDefaults write.
    nav.layerSelectionChanged()

    #expect(defaults.object(forKey: AppStorageKeys.selectedLayerIndex) == nil)
  }

  // MARK: - Path 3: model layer ID → layerSelection

  @Test("an externally-set layer ID is mirrored into the filtered index")
  func modelLayerIdChanged_mirrorsFilteredIndex() {
    let viewModel = makeViewModel()
    viewModel.layers = [makeLayer(0), makeLayer(1), makeLayer(2)]
    viewModel.layerFilterMode = .emotionsOnly // filtered layers: [1, 2]
    let nav = NavigationViewModel(
      contentViewModel: viewModel,
      initialLayer: 0,
      initialPhaseSelection: 1,
      userDefaults: freshDefaults()
    )

    viewModel.selectedLayerId = 2
    nav.modelLayerIdChanged()

    #expect(nav.layerSelection == 1)
  }

  @Test("a nil layer ID leaves layerSelection untouched")
  func modelLayerIdChanged_nilLayerId_isNoOp() {
    let viewModel = makeViewModel()
    viewModel.layers = [makeLayer(0), makeLayer(1), makeLayer(2)]
    let nav = NavigationViewModel(
      contentViewModel: viewModel,
      initialLayer: 1,
      initialPhaseSelection: 1,
      userDefaults: freshDefaults()
    )

    // Valid before the catalog finishes loading; the guard must early-exit
    // rather than derive an index from a missing ID.
    viewModel.selectedLayerId = nil
    nav.modelLayerIdChanged()

    #expect(nav.layerSelection == 1)
  }

  // MARK: - Path 4: filter-mode change re-derives the filtered index (#180)

  @Test("a filter-mode change re-derives the filtered index for the selected layer")
  func filterModeChanged_reDerivesFilteredIndex() {
    let viewModel = makeViewModel()
    viewModel.layers = [makeLayer(0), makeLayer(1), makeLayer(2)]
    let nav = NavigationViewModel(
      contentViewModel: viewModel,
      initialLayer: 2,
      initialPhaseSelection: 1,
      userDefaults: freshDefaults()
    )
    viewModel.selectedLayerId = 2

    viewModel.layerFilterMode = .emotionsOnly // id 2 is now filtered index 1
    nav.filterModeChanged()

    #expect(nav.layerSelection == 1)
  }

  @Test("a filter-mode change clamps the index when no layer ID resolves")
  func filterModeChanged_clampsWhenLayerMissing() {
    let viewModel = makeViewModel()
    viewModel.layers = [makeLayer(0), makeLayer(1), makeLayer(2)]
    let nav = NavigationViewModel(
      contentViewModel: viewModel,
      initialLayer: 2,
      initialPhaseSelection: 1,
      userDefaults: freshDefaults()
    )
    viewModel.selectedLayerId = nil

    viewModel.layerFilterMode = .strategiesOnly // filtered layers: [0]
    nav.filterModeChanged()

    #expect(nav.layerSelection == 0)
  }

  @Test("a filter-mode change clamps when the selected layer is filtered out")
  func filterModeChanged_clampsWhenLayerFilteredOut() {
    let viewModel = makeViewModel()
    viewModel.layers = [makeLayer(0), makeLayer(1), makeLayer(2)]
    let nav = NavigationViewModel(
      contentViewModel: viewModel,
      initialLayer: 2,
      initialPhaseSelection: 1,
      userDefaults: freshDefaults()
    )
    // Layer categorization is purely ID-based (`LayerFilterMode.filter`):
    // id 0 is the strategies layer, ids >= 1 are emotion layers. So id 1
    // belongs to `.emotionsOnly` and is dropped by `.strategiesOnly`.
    viewModel.selectedLayerId = 1

    viewModel.layerFilterMode = .strategiesOnly // [0]; layer 1 is filtered out
    nav.filterModeChanged()

    #expect(nav.layerSelection == 0)
  }

  // MARK: - Path 5: phaseSelection → model

  @Test("a phaseSelection change normalizes the offset and writes the model + AppStorage")
  func phaseSelectionChanged_normalizesAndPersists() {
    let viewModel = makeViewModel()
    viewModel.phaseOrder = sixPhases
    let defaults = freshDefaults()
    let nav = NavigationViewModel(
      contentViewModel: viewModel,
      initialLayer: 0,
      initialPhaseSelection: 1,
      userDefaults: defaults
    )

    nav.phaseSelection = 3 // real page 3 → zero-based index 2

    #expect(viewModel.selectedPhaseIndex == 2)
    #expect(defaults.integer(forKey: AppStorageKeys.selectedPhaseIndex) == 2)
  }

  @Test("a phaseSelection change is a no-op when phaseOrder is empty")
  func phaseSelectionChanged_emptyPhaseOrder_isNoOp() {
    let viewModel = makeViewModel() // phaseOrder defaults to []
    let nav = NavigationViewModel(
      contentViewModel: viewModel,
      initialLayer: 0,
      initialPhaseSelection: 1,
      userDefaults: freshDefaults()
    )

    nav.phaseSelection = 3

    // View-side value is left as the user set it; only the model write
    // is suppressed. The early-return path must not eagerly clamp.
    #expect(nav.phaseSelection == 3)
    #expect(viewModel.selectedPhaseIndex == 0)
  }

  @Test("a sentinel phaseSelection wraps eagerly and writes the snapped index")
  func phaseSelectionChanged_sentinelWraps() {
    let viewModel = makeViewModel()
    viewModel.phaseOrder = sixPhases
    let nav = NavigationViewModel(
      contentViewModel: viewModel,
      initialLayer: 0,
      initialPhaseSelection: 1,
      userDefaults: freshDefaults()
    )

    nav.phaseSelection = 0 // leading sentinel → wraps to last real page (6)

    // Eager correction: phaseSelection is snapped synchronously inside the
    // same didSet so SwiftUI never renders the sentinel frame.
    #expect(nav.phaseSelection == 6)
    #expect(viewModel.selectedPhaseIndex == 5)
  }

  @Test("a trailing-sentinel phaseSelection wraps eagerly to the first real page")
  func phaseSelectionChanged_trailingSentinelWraps() {
    let viewModel = makeViewModel()
    viewModel.phaseOrder = sixPhases
    let nav = NavigationViewModel(
      contentViewModel: viewModel,
      initialLayer: 0,
      initialPhaseSelection: 1,
      userDefaults: freshDefaults()
    )

    nav.phaseSelection = 7 // trailing sentinel → wraps to first real page (1)

    #expect(nav.phaseSelection == 1)
    #expect(viewModel.selectedPhaseIndex == 0)
  }

  // MARK: - Path 6: model phase index → phaseSelection

  @Test("an externally-set phase index is mirrored as the +1 offset")
  func modelPhaseIndexChanged_mirrorsOffset() {
    let viewModel = makeViewModel()
    viewModel.phaseOrder = sixPhases
    let nav = NavigationViewModel(
      contentViewModel: viewModel,
      initialLayer: 0,
      initialPhaseSelection: 1,
      userDefaults: freshDefaults()
    )

    viewModel.selectedPhaseIndex = 4
    nav.modelPhaseIndexChanged()

    #expect(nav.phaseSelection == 5)
  }

  @Test("a phaseSelection write round-trips back to the same offset")
  func phaseSelection_roundTripsThroughModel() {
    let viewModel = makeViewModel()
    viewModel.phaseOrder = sixPhases
    let nav = NavigationViewModel(
      contentViewModel: viewModel,
      initialLayer: 0,
      initialPhaseSelection: 1,
      userDefaults: freshDefaults()
    )

    nav.phaseSelection = 4
    nav.modelPhaseIndexChanged()

    #expect(nav.phaseSelection == 4)
  }

  // MARK: - Path 1: phaseOrder change re-normalizes a stale offset

  @Test("a phaseOrder change re-normalizes a stale sentinel offset")
  func phaseOrderChanged_renormalizesSentinel() {
    let viewModel = makeViewModel()
    let nav = NavigationViewModel(
      contentViewModel: viewModel,
      initialLayer: 0,
      initialPhaseSelection: 7, // trailing sentinel for a six-phase order
      userDefaults: freshDefaults()
    )

    viewModel.phaseOrder = sixPhases
    nav.phaseOrderChanged()

    #expect(nav.phaseSelection == 1)
  }

  @Test("a phaseOrder change is a no-op when phaseOrder is empty")
  func phaseOrderChanged_emptyPhaseOrder_isNoOp() {
    let viewModel = makeViewModel() // phaseOrder defaults to []
    let nav = NavigationViewModel(
      contentViewModel: viewModel,
      initialLayer: 0,
      initialPhaseSelection: 7,
      userDefaults: freshDefaults()
    )

    nav.phaseOrderChanged()

    #expect(nav.phaseSelection == 7)
  }

  // MARK: - Round-trip

  @Test("a layerSelection write round-trips back to the same filtered index")
  func layerSelection_roundTripsThroughModel() {
    let viewModel = makeViewModel()
    viewModel.layers = [makeLayer(0), makeLayer(1), makeLayer(2)]
    let nav = NavigationViewModel(
      contentViewModel: viewModel,
      initialLayer: 0,
      initialPhaseSelection: 1,
      userDefaults: freshDefaults()
    )

    nav.layerSelection = 2
    nav.modelLayerIdChanged()

    #expect(nav.layerSelection == 2)
  }
}
