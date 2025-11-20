import SwiftUI

/// A reusable component for navigating through filtered layers and phases.
///
/// This component provides dual-axis navigation:
/// - Vertical (layer) scrolling via digital crown, swipe gestures, and programmatic scroll
/// - Horizontal (phase) scrolling within each layer via TabView
///
/// The component works with any filtered array of layers, making it suitable for:
/// - Browse mode (.all): All layers 0-10
/// - Emotion selection (.emotionsOnly): Layers 1-10
/// - Strategy selection (.strategiesOnly): Layer 0 only
struct FilteredLayerNavigationView: View {
  let layers: [CatalogLayerModel]
  let phaseOrder: [String]
  @Binding var selectedLayerIndex: Int
  @Binding var selectedPhaseIndex: Int
  let onPhaseCardTap: () -> Void

  @State private var layerSelection: Int = 0
  @State private var phaseSelection: Int = 1
  @State private var showLayerIndicator = false
  @State private var hideIndicatorTask: Task<Void, Never>?

  var body: some View {
    GeometryReader { geometry in
      ScrollViewReader { proxy in
        ScrollView(.vertical, showsIndicators: false) {
          LazyVStack(spacing: -20) {
            ForEach(layers.indices, id: \.self) { index in
              let layer = layers[index]
              FilteredLayerCardView(
                layer: layer,
                phaseOrder: phaseOrder,
                phaseSelection: $phaseSelection,
                layerIndex: index,
                selectedLayerIndex: layerSelection,
                geometry: geometry,
                onPhaseCardTap: onPhaseCardTap
              )
              .id(index)
            }
          }
          .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollDisabled(false)
        .scrollPosition(id: .init(
          get: { layerSelection },
          set: { newId in
            if let newId = newId as? Int, newId != layerSelection {
              layerSelection = newId
            }
          }
        ))
        .digitalCrownRotation(
          .init(
            get: { Double(layerSelection) },
            set: { newValue in
              guard layers.count > 0 else { return }
              let clampedValue = Int(round(newValue)).clamped(to: 0 ... (layers.count - 1))
              if clampedValue != layerSelection {
                layerSelection = clampedValue
              }
            }
          ),
          from: 0,
          through: Double(max(layers.count - 1, 0)),
          by: 1.0,
          sensitivity: .medium,
          isContinuous: false,
          isHapticFeedbackEnabled: true
        )
        .onChange(of: layerSelection) { _, newValue in
          guard layers.count > 0, newValue < layers.count else { return }
          withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo(newValue, anchor: .center)
          }
          showLayerIndicator = true
          scheduleLayerIndicatorHide()
          selectedLayerIndex = newValue
        }
        .onChange(of: phaseSelection) { _, newValue in
          guard phaseOrder.count > 0 else { return }
          let adjusted = PhaseNavigator.adjustedSelection(newValue, phaseCount: phaseOrder.count)
          if adjusted != newValue {
            phaseSelection = adjusted
          }
          let normalized = PhaseNavigator.normalizedIndex(adjusted, phaseCount: phaseOrder.count)
          selectedPhaseIndex = normalized
        }
        .onAppear {
          layerSelection = selectedLayerIndex
          phaseSelection = selectedPhaseIndex + 1
          guard layers.count > 0, layerSelection < layers.count else { return }
          proxy.scrollTo(layerSelection, anchor: .center)
          showLayerIndicator = true
          scheduleLayerIndicatorHide()
        }
        .overlay(alignment: .trailing) {
          layerIndicator(in: geometry.size)
        }
        .simultaneousGesture(
          DragGesture()
            .onEnded { value in
              let threshold: CGFloat = 30
              if value.translation.height > threshold, layerSelection > 0 {
                layerSelection -= 1
              } else if value.translation.height < -threshold, layerSelection < layers.count - 1 {
                layerSelection += 1
              }
              showLayerIndicator = true
              scheduleLayerIndicatorHide()
            }
        )
      }
    }
  }

  private func layerIndicator(in size: CGSize) -> some View {
    VStack {
      Spacer()
      ZStack(alignment: .top) {
        // Background track
        Capsule()
          .fill(Color.white.opacity(0.1))
          .frame(width: 4, height: size.height * 0.5)

        // Current layer indicators stack
        VStack(spacing: 2) {
          ForEach(layers.indices, id: \.self) { index in
            let layer = layers[index]
            let isSelected = index == layerSelection
            let distance = abs(index - layerSelection)

            Capsule()
              .fill(
                isSelected ?
                  LinearGradient(
                    gradient: Gradient(colors: [
                      Color(stage: layer.color),
                      Color(stage: layer.color).opacity(0.7),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                  ) :
                  LinearGradient(
                    gradient: Gradient(colors: [
                      Color(stage: layer.color).opacity(0.3),
                      Color(stage: layer.color).opacity(0.1),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                  )
              )
              .frame(
                width: isSelected ? 8 : 4,
                height: isSelected ? 16 : 8
              )
              .overlay(
                Capsule()
                  .stroke(
                    isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.1),
                    lineWidth: 0.5
                  )
              )
              .shadow(
                color: isSelected ? Color(stage: layer.color) : Color.clear,
                radius: isSelected ? 3 : 0
              )
              .scaleEffect(distance > 2 ? 0.6 : 1.0)
              .opacity(distance > 3 ? 0 : 1)
              .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: layerSelection)
          }
        }
      }
      .padding(.trailing, 6)
      Spacer()
    }
    .opacity(showLayerIndicator ? 1 : 0)
    .transition(.opacity)
  }

  private func scheduleLayerIndicatorHide() {
    hideIndicatorTask?.cancel()
    hideIndicatorTask = Task {
      try? await Task.sleep(nanoseconds: 1_000_000_000)
      guard !Task.isCancelled else { return }
      await MainActor.run {
        withAnimation(.easeOut(duration: 0.3)) {
          showLayerIndicator = false
        }
      }
    }
  }
}

/// Card view for a single layer in the filtered navigation.
private struct FilteredLayerCardView: View {
  let layer: CatalogLayerModel
  let phaseOrder: [String]
  @Binding var phaseSelection: Int
  let layerIndex: Int
  let selectedLayerIndex: Int
  let geometry: GeometryProxy
  let onPhaseCardTap: () -> Void

  private var transformEffect: (scale: CGFloat, rotation: Double, offset: CGFloat, opacity: Double) {
    let distance = layerIndex - selectedLayerIndex

    switch distance {
    case 0:
      return (scale: 1.0, rotation: 0, offset: 0, opacity: 1.0)
    case 1:
      return (scale: 0.95, rotation: -5, offset: 15, opacity: 0.3)
    case -1:
      return (scale: 0.95, rotation: 5, offset: -15, opacity: 0.3)
    default:
      return (scale: 0.85, rotation: 0, offset: 0, opacity: 0.0)
    }
  }

  var body: some View {
    FilteredLayerView(
      layer: layer,
      phaseOrder: phaseOrder,
      phaseSelection: $phaseSelection,
      onPhaseCardTap: onPhaseCardTap
    )
    .frame(width: geometry.size.width, height: geometry.size.height)
    .scaleEffect(transformEffect.scale)
    .rotation3DEffect(
      .degrees(transformEffect.rotation),
      axis: (x: 1, y: 0, z: 0),
      perspective: 0.8
    )
    .offset(y: transformEffect.offset)
    .opacity(transformEffect.opacity)
    .zIndex(layerIndex == selectedLayerIndex ? 10 : Double(10 - abs(layerIndex - selectedLayerIndex)))
    .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: selectedLayerIndex)
  }
}

/// Layer view with horizontal phase navigation.
private struct FilteredLayerView: View {
  let layer: CatalogLayerModel
  let phaseOrder: [String]
  @Binding var phaseSelection: Int
  let onPhaseCardTap: () -> Void
  @State private var showPageIndicator = false
  @State private var hideIndicatorTask: Task<Void, Never>?

  private var phaseCount: Int { phaseOrder.count }

  var body: some View {
    TabView(selection: $phaseSelection) {
      ForEach(0 ..< (phaseCount + 2), id: \.self) { index in
        if phaseCount == 0 { EmptyView() }
        else {
          let normalized = (index + phaseCount - 1) % phaseCount
          let phase = layer.phases[normalized]
          FilteredPhasePageView(
            layer: layer,
            phase: phase,
            color: Color(stage: layer.color),
            onTap: onPhaseCardTap
          )
          .tag(index)
        }
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .onChange(of: phaseSelection) { _, _ in
      showIndicator()
    }
    .overlay(alignment: .bottom) {
      if showPageIndicator {
        pageIndicator
          .transition(.opacity)
      }
    }
    .onAppear {
      showIndicator()
    }
  }

  private var pageIndicator: some View {
    HStack(spacing: 4) {
      ForEach(0 ..< phaseCount, id: \.self) { index in
        let normalized = PhaseNavigator.normalizedIndex(phaseSelection, phaseCount: phaseCount)
        let isSelected = index == normalized
        Circle()
          .fill(isSelected ? Color.white : Color.white.opacity(0.3))
          .frame(width: isSelected ? 6 : 4, height: isSelected ? 6 : 4)
          .animation(.easeInOut(duration: 0.2), value: phaseSelection)
      }
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(
      Capsule()
        .fill(Color.black.opacity(0.6))
        .overlay(
          Capsule()
            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    )
    .padding(.bottom, 8)
  }

  private func showIndicator() {
    withAnimation(.easeIn(duration: 0.2)) {
      showPageIndicator = true
    }
    hideIndicatorTask?.cancel()
    hideIndicatorTask = Task {
      try? await Task.sleep(nanoseconds: 1_000_000_000)
      guard !Task.isCancelled else { return }
      await MainActor.run {
        withAnimation(.easeOut(duration: 0.3)) {
          showPageIndicator = false
        }
      }
    }
  }
}

/// Phase page view with tap callback support.
private struct FilteredPhasePageView: View {
  let layer: CatalogLayerModel
  let phase: CatalogPhaseModel
  let color: Color
  let onTap: () -> Void

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Background
        VStack(spacing: 0) {
          Spacer()

          // Mystical floating crystal interface
          ZStack {
            // Mystical background orb with layer color
            Circle()
              .fill(
                RadialGradient(
                  gradient: Gradient(colors: [
                    color.opacity(0.3),
                    color.opacity(0.1),
                    Color.clear,
                  ]),
                  center: .center,
                  startRadius: 20,
                  endRadius: 80
                )
              )
              .frame(width: 160, height: 160)
              .blur(radius: 1)

            // Main content container - floating card
            VStack(spacing: 12) {
              // Layer context - minimal and elegant
              VStack(spacing: 4) {
                Text(layer.title)
                  .font(.caption)
                  .fontWeight(.medium)
                  .foregroundColor(.white.opacity(0.7))
                  .tracking(1.5)
                  .textCase(.uppercase)
                  .lineLimit(1)
                  .minimumScaleFactor(0.8)

                Text(layer.subtitle)
                  .font(.caption2)
                  .foregroundColor(.white.opacity(0.5))
                  .lineLimit(1)
                  .minimumScaleFactor(0.8)
              }

              // Hero phase name with sophisticated treatment
              Text(phase.name)
                .font(.largeTitle)
                .fontWeight(.light)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .padding(.horizontal, 4)

              // Mystical accent - geometric crystal element
              ZStack {
                // Outer glow
                Capsule()
                  .fill(color.opacity(0.3))
                  .frame(width: 60, height: 3)
                  .blur(radius: 3)

                // Inner crystal line
                Capsule()
                  .fill(
                    LinearGradient(
                      gradient: Gradient(colors: [
                        color.opacity(0.6),
                        color,
                        color.opacity(0.6),
                      ]),
                      startPoint: .leading,
                      endPoint: .trailing
                    )
                  )
                  .frame(width: 50, height: 2)
                  .shadow(color: color.opacity(0.8), radius: 4)
              }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
              // Floating card background
              RoundedRectangle(cornerRadius: 16)
                .fill(
                  LinearGradient(
                    gradient: Gradient(colors: [
                      Color.black.opacity(0.4),
                      Color.black.opacity(0.6),
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  )
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 16)
                    .stroke(
                      LinearGradient(
                        gradient: Gradient(colors: [
                          color.opacity(0.3),
                          Color.white.opacity(0.1),
                          color.opacity(0.2),
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                      lineWidth: 1
                    )
                )
                .shadow(color: color.opacity(0.2), radius: 8)
                .shadow(color: .black.opacity(0.3), radius: 4)
            )
            .onTapGesture {
              onTap()
            }
          }
          .frame(maxWidth: .infinity)

          Spacer()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

          // Bottom gutter for page indicators
          Spacer()
            .frame(height: 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
          LinearGradient(
            gradient: Gradient(colors: [
              Color.black.opacity(0.98),
              Color.black.opacity(0.9),
              Color.black,
            ]),
            startPoint: .top,
            endPoint: .bottom
          )
          .overlay(
            RadialGradient(
              gradient: Gradient(colors: [
                color.opacity(0.18),
                Color.clear,
              ]),
              center: .center,
              startRadius: 20,
              endRadius: min(geometry.size.width, geometry.size.height) * 0.9
            )
          )
        )
        .ignoresSafeArea(.all)
      }
    }
  }
}
