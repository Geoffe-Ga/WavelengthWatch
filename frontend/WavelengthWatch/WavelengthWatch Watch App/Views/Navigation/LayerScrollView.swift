import SwiftUI

/// Vertical layer scroller — the outer axis of the dual-axis navigation.
///
/// Renders the filtered layers from `ContentViewModel` as full-screen
/// `LayerCardView` pages and hosts the digital-crown / drag-gesture /
/// scroll-position bindings. Position is shown by the always-visible side rail
/// (`LayerSideIndicator`) and the per-phase page dots — there are no
/// directional arrows.
struct LayerScrollView: View {
  @ObservedObject var viewModel: ContentViewModel
  @Binding var layerSelection: Int
  @Binding var phaseSelection: Int

  /// Ambient opacity for the always-visible layer position rail.
  private let sideRailAmbientOpacity: Double = 0.35

  /// Clamps `layerSelection` to the current filtered range so bindings
  /// can never read an out-of-range index — important during filter-mode
  /// transitions where `layerSelection` may be stale for one render.
  private var clampedSelection: Int {
    guard !viewModel.filteredLayers.isEmpty else { return 0 }
    return min(layerSelection, viewModel.filteredLayers.count - 1)
  }

  var body: some View {
    GeometryReader { geometry in
      ScrollViewReader { proxy in
        scrollView(geometry: geometry)
          .scrollTargetBehavior(.paging)
          .scrollPosition(id: Binding<Int?>(
            get: { clampedSelection },
            set: { newId in
              if let newId, newId != layerSelection {
                layerSelection = newId
              }
            }
          ))
          .digitalCrownRotation(
            Binding<Double>(
              get: { Double(clampedSelection) },
              set: { newValue in
                guard !viewModel.filteredLayers.isEmpty else { return }
                let clampedValue = Int(round(newValue))
                  .clamped(to: 0 ... (viewModel.filteredLayers.count - 1))
                if clampedValue != layerSelection {
                  layerSelection = clampedValue
                }
              }
            ),
            from: 0,
            through: Double(max(viewModel.filteredLayers.count - 1, 0)),
            by: 1.0,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
          )
          .onChange(of: layerSelection) { _, newValue in
            guard !viewModel.filteredLayers.isEmpty,
                  newValue < viewModel.filteredLayers.count else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
              proxy.scrollTo(newValue, anchor: .center)
            }
          }
          .onAppear {
            guard !viewModel.filteredLayers.isEmpty,
                  layerSelection < viewModel.filteredLayers.count else { return }
            proxy.scrollTo(layerSelection, anchor: .center)
          }
          .overlay(alignment: .trailing) {
            sideIndicator(in: geometry.size)
          }
          .overlay(alignment: .bottomTrailing) {
            navigationChevron
          }
          // DragGesture writes raw `layerSelection`; the bounds check uses
          // `filteredLayers.count` since reads downstream are clamped via
          // `clampedSelection`.
          .simultaneousGesture(
            DragGesture()
              .onEnded { value in
                let threshold: CGFloat = 30
                if value.translation.height > threshold, layerSelection > 0 {
                  layerSelection -= 1
                } else if value.translation.height < -threshold,
                          layerSelection < viewModel.filteredLayers.count - 1
                {
                  layerSelection += 1
                }
              }
          )
      }
    }
  }

  // MARK: - Navigation chevron

  /// The layer currently centered in the vertical scroller.
  private var currentLayer: CatalogLayerModel? {
    let layers = viewModel.filteredLayers
    guard !layers.isEmpty else { return nil }
    // Re-clamp against this exact snapshot: `clampedSelection` reads
    // `filteredLayers.count` in a separate access, so a filter change between
    // the two could momentarily push it past this `layers`' bounds.
    return layers[min(clampedSelection, layers.count - 1)]
  }

  /// Single navigation chevron, pinned to the viewport's bottom-trailing
  /// corner, navigating to the currently centered layer/phase. Replaces the
  /// former per-page chevron (one per `PhasePageView`), which a viewport-
  /// overflowing card could push out of sight and which lazily realized pages
  /// left intermittently uncomposited (#457). One always-present chevron at a
  /// fixed viewport position sidesteps both.
  ///
  /// The phase is read straight from `phaseSelection` — the same binding the
  /// inner `TabView` is driven by — and normalized with the same
  /// `PhaseNavigator` math the pages use, so the destination always matches the
  /// page actually on screen, even mid-scroll (no reliance on the separately
  /// derived `selectedPhaseIndex`, which can lag a render behind).
  @ViewBuilder
  private var navigationChevron: some View {
    if let layer = currentLayer, !layer.phases.isEmpty {
      // `normalizedIndex` is `(selection - 1 + n) % n`, which for any phaseCount
      // n > 0 (guaranteed by the `!isEmpty` check) returns a value in 0..<n — so
      // it indexes `phases` safely without a further clamp.
      let normalized = PhaseNavigator.normalizedIndex(
        phaseSelection, phaseCount: layer.phases.count
      )
      let phase = layer.phases[normalized]
      NavigationLink(value: DetailDestination.forPhase(in: layer, phase: phase)) {
        Image(systemName: "chevron.right.circle.fill")
          .foregroundStyle(.white.opacity(0.8))
          .font(.title2)
          .background(
            Circle()
              .fill(Color(stage: layer.color).opacity(0.3))
              .frame(width: 32, height: 32)
          )
      }
      .buttonStyle(.plain)
      .padding(.trailing, 12)
      .padding(.bottom, 20)
    }
  }

  // MARK: - Subviews

  private func scrollView(geometry: GeometryProxy) -> some View {
    // Zero spacing + per-page `containerRelativeFrame` (in LayerCardView) +
    // `.paging` give exact, non-overlapping pages with no resting offset.
    ScrollView(.vertical, showsIndicators: false) {
      LazyVStack(spacing: 0) {
        ForEach(viewModel.filteredLayers.indices, id: \.self) { index in
          let layer = viewModel.filteredLayers[index]
          LayerCardView(
            layer: layer,
            phaseCount: viewModel.phaseOrder.count,
            selection: $phaseSelection,
            screenWidth: geometry.size.width
          )
          .id(index)
        }
      }
      .scrollTargetLayout()
    }
  }

  /// Minimal, always-visible position rail (which layer of how many). Held
  /// at a low opacity so it reads as ambient context and never competes with
  /// the content.
  private func sideIndicator(in size: CGSize) -> some View {
    LayerSideIndicator(
      layers: viewModel.filteredLayers,
      selection: clampedSelection,
      size: size
    )
    .opacity(sideRailAmbientOpacity)
  }
}
