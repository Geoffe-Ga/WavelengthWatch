import SwiftUI

/// Vertical layer scroller — the outer axis of the dual-axis navigation.
///
/// Renders the filtered layers from `ContentViewModel` as full-screen
/// `LayerCardView` pages, hosts the digital-crown / drag-gesture / scroll
/// position bindings, and owns the auto-hiding side indicator.
///
/// The indicator state (visibility + hide-after task) lives here rather
/// than on `ContentView` because it's a property of the scroll surface
/// itself: every interaction that nudges the layer selection on this
/// view flashes the indicator and re-arms the auto-hide.
struct LayerScrollView: View {
  @ObservedObject var viewModel: ContentViewModel
  @Binding var layerSelection: Int
  @Binding var phaseSelection: Int

  @State private var showIndicator = false
  @State private var hideIndicatorTask: Task<Void, Never>?

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
          .scrollTargetBehavior(.viewAligned)
          .scrollDisabled(false)
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
            flashIndicator()
          }
          .onAppear {
            guard !viewModel.filteredLayers.isEmpty,
                  layerSelection < viewModel.filteredLayers.count else { return }
            proxy.scrollTo(layerSelection, anchor: .center)
            flashIndicator()
          }
          .overlay(alignment: .trailing) {
            sideIndicator(in: geometry.size)
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
                flashIndicator()
              }
          )
      }
    }
  }

  // MARK: - Subviews

  private func scrollView(geometry: GeometryProxy) -> some View {
    ScrollView(.vertical, showsIndicators: false) {
      LazyVStack(spacing: -20) {
        ForEach(viewModel.filteredLayers.indices, id: \.self) { index in
          let layer = viewModel.filteredLayers[index]
          LayerCardView(
            layer: layer,
            phaseCount: viewModel.phaseOrder.count,
            selection: $phaseSelection,
            layerIndex: index,
            selectedLayerIndex: clampedSelection,
            geometry: geometry,
            screenWidth: geometry.size.width
          )
          .id(index)
        }
      }
      .scrollTargetLayout()
    }
  }

  private func sideIndicator(in size: CGSize) -> some View {
    LayerSideIndicator(
      layers: viewModel.filteredLayers,
      selection: clampedSelection,
      size: size
    )
    .opacity(showIndicator ? 1 : 0)
    .transition(.opacity)
  }

  // MARK: - Indicator lifecycle

  private func flashIndicator() {
    showIndicator = true
    scheduleHide()
  }

  private func scheduleHide() {
    hideIndicatorTask?.cancel()
    hideIndicatorTask = Task {
      try? await Task.sleep(nanoseconds: 1_000_000_000)
      guard !Task.isCancelled else { return }
      await MainActor.run {
        withAnimation(.easeOut(duration: 0.3)) {
          showIndicator = false
        }
      }
    }
  }
}
