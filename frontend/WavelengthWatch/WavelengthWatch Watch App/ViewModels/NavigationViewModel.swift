import Combine
import Foundation

/// Owns the dual-axis navigation selection and keeps it reconciled with
/// `ContentViewModel`'s ground-truth IDs and indices.
///
/// `layerSelection` (a filtered-array index) and `phaseSelection` (an
/// infinite-scroll TabView page, including the sentinel pages at `0` and
/// `phaseCount + 1`) are the SwiftUI-facing selection values. They are
/// projections of `ContentViewModel`'s `selectedLayerId` /
/// `selectedPhaseIndex`, which stay the source of truth.
///
/// This replaces the six-observer `NavigationSyncModifier` (#329):
/// - **View → model** runs in the `didSet`s below (a scroll/crown/swipe
///   moved the selection).
/// - **Model → view** runs in `observeModel()`'s Combine subscriptions
///   (the catalog loaded, the filter mode changed, an entry was logged).
///
/// Every cross-write is equality-guarded so the two representations
/// converge instead of looping.
@MainActor
final class NavigationViewModel: ObservableObject {
  /// Filtered-array index of the selected layer (outer scroll axis).
  @Published var layerSelection: Int {
    didSet { layerSelectionChanged() }
  }

  /// Infinite-scroll TabView page for the selected phase, including the
  /// sentinel pages at `0` and `phaseCount + 1` (inner scroll axis).
  @Published var phaseSelection: Int {
    didSet { phaseSelectionChanged() }
  }

  private let contentViewModel: ContentViewModel
  private let userDefaults: UserDefaults
  private var cancellables: Set<AnyCancellable> = []

  init(
    contentViewModel: ContentViewModel,
    initialLayer: Int,
    initialPhaseSelection: Int,
    userDefaults: UserDefaults = .standard
  ) {
    self.contentViewModel = contentViewModel
    self.userDefaults = userDefaults
    // Property observers do not fire for assignments made in `init`, so
    // seeding here does not kick off a spurious view → model write.
    self.layerSelection = initialLayer
    self.phaseSelection = initialPhaseSelection
    observeModel()
  }

  // MARK: - Model observation

  /// Subscribes to the four `ContentViewModel` publishers whose changes
  /// must flow back into the selection. `dropFirst()` skips the value
  /// Combine replays on subscribe; each handler is dispatched onto a
  /// fresh main-actor `Task` so it runs *after* the model property — and
  /// any `didSet` it triggers — has fully settled.
  private func observeModel() {
    contentViewModel.$phaseOrder
      .dropFirst()
      .sink { [weak self] _ in Task { @MainActor in self?.phaseOrderChanged() } }
      .store(in: &cancellables)

    contentViewModel.$selectedLayerId
      .dropFirst()
      .sink { [weak self] _ in Task { @MainActor in self?.modelLayerIdChanged() } }
      .store(in: &cancellables)

    contentViewModel.$layerFilterMode
      .dropFirst()
      .sink { [weak self] _ in Task { @MainActor in self?.filterModeChanged() } }
      .store(in: &cancellables)

    contentViewModel.$selectedPhaseIndex
      .dropFirst()
      .sink { [weak self] _ in Task { @MainActor in self?.modelPhaseIndexChanged() } }
      .store(in: &cancellables)
  }

  // The six reconciliation handlers below are `internal` (not `private`)
  // so `NavigationViewModelTests` can drive each path directly and
  // synchronously; they are not meant to be called from elsewhere.

  // MARK: - View → model

  /// A new filtered index resolves to a layer ID; mirror it into the
  /// model's ID + full-array index and persist the latter.
  func layerSelectionChanged() {
    guard let layerId = contentViewModel.filteredIndexToLayerId(layerSelection) else { return }
    contentViewModel.selectedLayerId = layerId
    if let fullIndex = contentViewModel.layerIdToIndex(layerId) {
      contentViewModel.selectedLayerIndex = fullIndex
      userDefaults.set(fullIndex, forKey: AppStorageKeys.selectedLayerIndex)
    }
  }

  /// Normalize the infinite-scroll offset to a canonical zero-based phase
  /// index and write it to the model + persistence. The sentinel pages
  /// are normalized virtually here; `phaseSelection` itself is corrected
  /// by `modelPhaseIndexChanged()` on the resulting model change, so this
  /// never mutates `phaseSelection` inside its own `didSet`.
  ///
  /// Because that correction arrives one async hop later (via the Combine
  /// sink → `Task`), SwiftUI may briefly render the sentinel page before
  /// it snaps to the wrapped phase. This is imperceptible on device; the
  /// old `NavigationSyncModifier` corrected it synchronously.
  func phaseSelectionChanged() {
    guard !contentViewModel.phaseOrder.isEmpty else { return }
    let count = contentViewModel.phaseOrder.count
    let adjusted = PhaseNavigator.adjustedSelection(phaseSelection, phaseCount: count)
    let normalized = PhaseNavigator.normalizedIndex(adjusted, phaseCount: count)
    // phaseSelection is intentionally not corrected here; a sentinel page
    // is fixed by modelPhaseIndexChanged() once this model write settles.
    contentViewModel.selectedPhaseIndex = normalized
    userDefaults.set(normalized, forKey: AppStorageKeys.selectedPhaseIndex)
  }

  // MARK: - Model → view

  /// `phaseOrder` changed (catalog loaded/refreshed) — re-normalize a
  /// stale sentinel offset against the new phase count.
  func phaseOrderChanged() {
    guard !contentViewModel.phaseOrder.isEmpty else { return }
    let adjusted = PhaseNavigator.adjustedSelection(
      phaseSelection,
      phaseCount: contentViewModel.phaseOrder.count
    )
    if adjusted != phaseSelection {
      phaseSelection = adjusted
    }
  }

  /// An externally-set layer ID must be mirrored back into the filtered
  /// index that the scroller observes.
  func modelLayerIdChanged() {
    guard let layerId = contentViewModel.selectedLayerId,
          let filteredIndex = contentViewModel.layerIdToFilteredIndex(layerId)
    else { return }
    if layerSelection != filteredIndex {
      layerSelection = filteredIndex
    }
  }

  /// A filter-mode change invalidates the filtered index for the current
  /// layer ID — re-derive it (or clamp to the new range). Fixes #180:
  /// strategy cards rendered tiny after flow completion because
  /// `layerSelection` was not re-derived.
  func filterModeChanged() {
    guard let layerId = contentViewModel.selectedLayerId,
          let filteredIndex = contentViewModel.layerIdToFilteredIndex(layerId)
    else {
      // Either no layer is selected, or the selected layer fell out of the
      // filtered set — clamp the index into the new filtered range. The
      // assignment cascades through `didSet` → `layerSelectionChanged()`,
      // which reconciles `selectedLayerId` once this returns.
      let maxIndex = max(0, contentViewModel.filteredLayers.count - 1)
      if layerSelection > maxIndex {
        layerSelection = maxIndex
      }
      return
    }
    if layerSelection != filteredIndex {
      layerSelection = filteredIndex
    }
  }

  /// An externally-set canonical phase index must be mirrored back as the
  /// infinite-scroll offset (index + 1).
  func modelPhaseIndexChanged() {
    let expected = contentViewModel.selectedPhaseIndex + 1
    if phaseSelection != expected {
      phaseSelection = expected
    }
  }
}
