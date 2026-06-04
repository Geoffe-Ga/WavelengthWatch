import SwiftUI

/// Vertical layer scroller — the outer axis of the dual-axis navigation.
///
/// Renders the filtered layers from `ContentViewModel` as full-screen
/// `LayerCardView` pages and hosts the digital-crown / drag-gesture /
/// scroll-position bindings. The directional chevrons and the position rail
/// are always present — a missing chevron means "you're at that edge" — and
/// their emphasis follows the live scroll phase rather than a timer, so they
/// can never disappear mid-scroll.
struct LayerScrollView: View {
  @ObservedObject var viewModel: ContentViewModel
  @Binding var layerSelection: Int
  @Binding var phaseSelection: Int

  /// Edge availability backing the directional chevrons.
  @StateObject private var affordanceModel = ScrollAffordanceModel()

  /// Timed reveal (lit / visible-unlit / hidden) for the directional chevrons.
  @StateObject private var visibilityModel = ScrollAffordanceVisibilityModel()

  /// Synthesises a scroll-end for programmatic moves that emit no reliable
  /// scroll-phase signal; cancelled/restarted on each new move.
  @State private var scrollEndTask: Task<Void, Never>?

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
          // Live scroll phase drives chevron emphasis — true for the whole
          // duration of a gesture (user drag, crown, or momentum), so the
          // chevrons stay prominent until the scroll actually settles.
          .onScrollPhaseChange { oldPhase, newPhase in
            affordanceModel.setInteracting(newPhase.isScrolling)
            // Only a real scroll->stop transition ends the reveal window, so the
            // initial layout's idle phase can't cut the first-load sequence short.
            if oldPhase.isScrolling, !newPhase.isScrolling {
              visibilityModel.scrollEnded()
            }
          }
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
          .onChange(of: layerSelection) { oldValue, newValue in
            guard !viewModel.filteredLayers.isEmpty,
                  newValue < viewModel.filteredLayers.count else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
              proxy.scrollTo(newValue, anchor: .center)
            }
            registerScroll(newValue > oldValue ? .down : .up)
            updateAffordances()
          }
          .onChange(of: phaseSelection) { oldValue, newValue in
            registerScroll(newValue >= oldValue ? .right : .left)
          }
          .onChange(of: viewModel.filteredLayers.count) { _, _ in
            updateAffordances()
          }
          .onChange(of: viewModel.phaseOrder.count) { _, _ in
            updateAffordances()
          }
          .onAppear {
            guard !viewModel.filteredLayers.isEmpty,
                  layerSelection < viewModel.filteredLayers.count else { return }
            proxy.scrollTo(layerSelection, anchor: .center)
            updateAffordances()
            visibilityModel.appeared()
          }
          .task(id: visibilityModel.version) {
            // Live driver: sleep to each timed deadline, then advance the pure
            // state machine. Restarts whenever an event bumps `version`.
            while let deadline = visibilityModel.nextDeadline {
              try? await Task.sleep(for: deadline)
              if Task.isCancelled { return }
              visibilityModel.advance(by: deadline)
            }
          }
          .overlay(alignment: .trailing) {
            sideIndicator(in: geometry.size)
          }
          .overlay {
            ScrollAffordanceView(state: visibilityModel.state)
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
  /// the content; it no longer hides on a timer.
  private func sideIndicator(in size: CGSize) -> some View {
    LayerSideIndicator(
      layers: viewModel.filteredLayers,
      selection: clampedSelection,
      size: size
    )
    .opacity(sideRailAmbientOpacity)
  }

  // MARK: - Affordances

  private func updateAffordances() {
    affordanceModel.update(
      layerSelection: clampedSelection,
      layerCount: viewModel.filteredLayers.count,
      phaseCount: viewModel.phaseOrder.count
    )
    visibilityModel.updateAvailability(affordanceModel.affordances)
  }

  /// Lights the scrolled direction, then synthesises a scroll-end after a
  /// short window so programmatic vertical moves (which emit no reliable
  /// scroll-phase signal) still light up and settle. Rapid moves coalesce.
  private func registerScroll(_ direction: ScrollDirection) {
    visibilityModel.scrollStarted(direction)
    scrollEndTask?.cancel()
    scrollEndTask = Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(350))
      if Task.isCancelled { return }
      visibilityModel.scrollEnded()
    }
  }
}
