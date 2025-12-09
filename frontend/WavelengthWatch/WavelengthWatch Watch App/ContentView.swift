import SwiftUI

// MARK: - UI Constants

private enum UIConstants {
  static let menuButtonSize: CGFloat = 20
}

// Environment key for tracking detail view visibility
private struct IsShowingDetailViewKey: EnvironmentKey {
  static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
  var isShowingDetailView: Binding<Bool> {
    get { self[IsShowingDetailViewKey.self] }
    set { self[IsShowingDetailViewKey.self] = newValue }
  }
}

extension Comparable {
  func clamped(to limits: ClosedRange<Self>) -> Self {
    min(max(self, limits.lowerBound), limits.upperBound)
  }
}

extension Color {
  init(stage: String) {
    switch stage {
    case "Beige": self = .brown
    case "Purple": self = .purple
    case "Red": self = .red
    case "Blue": self = .blue
    case "Orange": self = .orange
    case "Green": self = .green
    case "Yellow": self = .yellow
    case "Teal": self = .teal
    case "Ultraviolet": self = .indigo
    case "Clear Light": self = .white
    default: self = .gray
    }
  }
}

struct ContentView: View {
  @AppStorage("selectedLayerIndex") private var storedLayerIndex = 0
  @AppStorage("selectedPhaseIndex") private var storedPhaseIndex = 0
  @StateObject private var viewModel: ContentViewModel
  @StateObject private var flowCoordinator: FlowCoordinator
  @EnvironmentObject private var notificationDelegate: NotificationDelegate
  let journalClient: JournalClientProtocol
  @State private var layerSelection: Int
  @State private var phaseSelection: Int
  @State private var showLayerIndicator = false
  @State private var hideIndicatorTask: Task<Void, Never>?
  @State private var showingMenu = false
  @State private var isShowingDetailView = false

  init() {
    let configuration = AppConfiguration()
    let apiClient = APIClient(baseURL: configuration.apiBaseURL)
    let repository = CatalogRepository(
      remote: CatalogAPIService(apiClient: apiClient),
      cache: FileCatalogCacheStore()
    )
    let journalClient = JournalClient(apiClient: apiClient)
    self.journalClient = journalClient
    let initialLayer = UserDefaults.standard.integer(forKey: "selectedLayerIndex")
    let initialPhase = UserDefaults.standard.integer(forKey: "selectedPhaseIndex")
    let model = ContentViewModel(
      repository: repository,
      journalClient: journalClient,
      initialLayerIndex: initialLayer,
      initialPhaseIndex: initialPhase
    )
    _viewModel = StateObject(wrappedValue: model)
    let coordinator = FlowCoordinator(contentViewModel: model)
    _flowCoordinator = StateObject(wrappedValue: coordinator)
    _layerSelection = State(initialValue: initialLayer)
    _phaseSelection = State(initialValue: initialPhase + 1)
  }

  var body: some View {
    NavigationStack {
      ZStack {
        if viewModel.layers.isEmpty {
          if viewModel.isLoading {
            ProgressView("Loading curriculum…")
              .foregroundStyle(.white)
          } else if let error = viewModel.loadErrorMessage {
            VStack(spacing: 12) {
              Text(error)
                .multilineTextAlignment(.center)
              Button("Retry") {
                Task { await viewModel.retry() }
              }
            }
            .padding()
          } else {
            ProgressView("Loading curriculum…")
          }
        } else if viewModel.phaseOrder.isEmpty {
          Text("No phase information available.")
        } else {
          layeredContent
        }
      }
      .ignoresSafeArea(edges: .bottom)
      .task { await viewModel.loadCatalog() }
      .onChange(of: viewModel.phaseOrder) {
        adjustPhaseSelection()
      }
      .onChange(of: layerSelection) { _, newValue in
        // Convert filtered index to layer ID
        if let layerId = viewModel.filteredIndexToLayerId(newValue) {
          viewModel.selectedLayerId = layerId
          // Convert layer ID to full array index
          if let fullIndex = viewModel.layerIdToIndex(layerId) {
            viewModel.selectedLayerIndex = fullIndex
            storedLayerIndex = fullIndex
          }
        }
        showLayerIndicator = true
        scheduleLayerIndicatorHide()
      }
      .onChange(of: viewModel.selectedLayerId) { _, newLayerId in
        // When selectedLayerId changes, update layerSelection to match in filtered array
        guard let layerId = newLayerId else { return }
        if let filteredIndex = viewModel.layerIdToFilteredIndex(layerId) {
          if layerSelection != filteredIndex {
            layerSelection = filteredIndex
          }
        }
      }
      .onChange(of: phaseSelection) { _, newValue in
        guard viewModel.phaseOrder.count > 0 else { return }
        let adjusted = PhaseNavigator.adjustedSelection(newValue, phaseCount: viewModel.phaseOrder.count)
        if adjusted != newValue {
          phaseSelection = adjusted
        }
        let normalized = PhaseNavigator.normalizedIndex(adjusted, phaseCount: viewModel.phaseOrder.count)
        viewModel.selectedPhaseIndex = normalized
        storedPhaseIndex = normalized
      }
      .onChange(of: viewModel.selectedPhaseIndex) { _, newValue in
        let expected = newValue + 1
        if phaseSelection != expected {
          phaseSelection = expected
        }
      }
      .alert(item: $viewModel.journalFeedback) { feedback in
        switch feedback.kind {
        case .success:
          Alert(
            title: Text("Entry Logged"),
            message: Text("Thanks for checking in."),
            dismissButton: .default(Text("OK")) { viewModel.journalFeedback = nil }
          )
        case let .failure(message):
          Alert(
            title: Text("Something went wrong"),
            message: Text(message),
            dismissButton: .default(Text("OK")) { viewModel.journalFeedback = nil }
          )
        }
      }
      .alert("Primary emotion selected", isPresented: .constant(flowCoordinator.currentStep == .confirmingPrimary)) {
        Button("Add Secondary Emotion") {
          flowCoordinator.promptForSecondary()
        }
        Button("Skip to Review") {
          flowCoordinator.showReview()
        }
        Button("Cancel", role: .cancel) {
          flowCoordinator.cancel()
        }
      } message: {
        if let primary = flowCoordinator.selections.primary {
          Text("You selected \"\(primary.expression)\". Add a secondary emotion or skip to review?")
        }
      }
      .alert("Secondary emotion selected", isPresented: .constant(flowCoordinator.currentStep == .confirmingSecondary)) {
        Button("Add Strategy") {
          flowCoordinator.promptForStrategy()
        }
        Button("Skip to Review") {
          flowCoordinator.showReview()
        }
        Button("Cancel", role: .cancel) {
          flowCoordinator.cancel()
        }
      } message: {
        if let secondary = flowCoordinator.selections.secondary {
          Text("You selected \"\(secondary.expression)\". Add a strategy or skip to review?")
        } else {
          Text("Add a strategy or skip to review?")
        }
      }
      .alert("Strategy selected", isPresented: .constant(flowCoordinator.currentStep == .confirmingStrategy)) {
        Button("Continue to Review") {
          flowCoordinator.showReview()
        }
        Button("Cancel", role: .cancel) {
          flowCoordinator.cancel()
        }
      } message: {
        if let strategy = flowCoordinator.selections.strategy {
          Text("You selected \"\(strategy.strategy)\". Continue to review?")
        } else {
          Text("Continue to review?")
        }
      }
      .onChange(of: notificationDelegate.scheduledNotificationReceived) { _, newValue in
        if let notification = newValue {
          viewModel.setInitiatedBy(notification.initiatedBy)
          notificationDelegate.clearNotificationState()
        }
      }
      .sheet(isPresented: $showingMenu) {
        NavigationStack {
          MenuView(journalClient: journalClient)
            .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                  showingMenu = false
                }
              }
            }
        }
      }
      .sheet(isPresented: .constant(flowCoordinator.currentStep == .review)) {
        FlowReviewSheet(flowCoordinator: flowCoordinator)
      }
      .toolbar {
        if !isShowingDetailView {
          ToolbarItem(placement: .topBarLeading) {
            Button {
              showingMenu = true
            } label: {
              Image(systemName: "ellipsis.circle")
                .font(.system(size: UIConstants.menuButtonSize))
                .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .navigationTitle("")
    }
    .environmentObject(viewModel)
    .environmentObject(flowCoordinator)
    .environment(\.isShowingDetailView, $isShowingDetailView)
  }

  private var layeredContent: some View {
    GeometryReader { geometry in
      ScrollViewReader { proxy in
        ScrollView(.vertical, showsIndicators: false) {
          LazyVStack(spacing: -20) {
            ForEach(viewModel.filteredLayers.indices, id: \.self) { index in
              let layer = viewModel.filteredLayers[index]
              LayerCardView(
                layer: layer,
                phaseCount: viewModel.phaseOrder.count,
                selection: $phaseSelection,
                layerIndex: index,
                selectedLayerIndex: layerSelection,
                geometry: geometry
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
              guard viewModel.filteredLayers.count > 0 else { return }
              let clampedValue = Int(round(newValue)).clamped(to: 0 ... (viewModel.filteredLayers.count - 1))
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
          guard viewModel.filteredLayers.count > 0, newValue < viewModel.filteredLayers.count else { return }
          withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo(newValue, anchor: .center)
          }
        }
        .onAppear {
          guard viewModel.filteredLayers.count > 0, layerSelection < viewModel.filteredLayers.count else { return }
          proxy.scrollTo(layerSelection, anchor: .center)
          showLayerIndicator = true
          scheduleLayerIndicatorHide()
        }
        .overlay(alignment: .trailing) {
          enhancedLayerIndicator(in: geometry.size)
        }
        .simultaneousGesture(
          DragGesture()
            .onEnded { value in
              let threshold: CGFloat = 30
              if value.translation.height > threshold, layerSelection > 0 {
                layerSelection -= 1
              } else if value.translation.height < -threshold, layerSelection < viewModel.filteredLayers.count - 1 {
                layerSelection += 1
              }
              showLayerIndicator = true
              scheduleLayerIndicatorHide()
            }
        )
      }
    }
  }

  private func adjustPhaseSelection() {
    guard viewModel.phaseOrder.count > 0 else { return }
    let adjusted = PhaseNavigator.adjustedSelection(phaseSelection, phaseCount: viewModel.phaseOrder.count)
    if adjusted != phaseSelection {
      phaseSelection = adjusted
    }
  }

  private func enhancedLayerIndicator(in size: CGSize) -> some View {
    VStack {
      Spacer()
      ZStack(alignment: .top) {
        // Background track
        Capsule()
          .fill(Color.white.opacity(0.1))
          .frame(width: 4, height: size.height * 0.5)

        // Current layer indicators stack
        VStack(spacing: 2) {
          ForEach(viewModel.filteredLayers.indices, id: \.self) { index in
            let layer = viewModel.filteredLayers[index]
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

struct LayerCardView: View {
  let layer: CatalogLayerModel
  let phaseCount: Int
  @Binding var selection: Int
  let layerIndex: Int
  let selectedLayerIndex: Int
  let geometry: GeometryProxy
  @EnvironmentObject private var viewModel: ContentViewModel

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
    LayerView(
      layer: layer,
      phaseCount: phaseCount,
      selection: $selection
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

struct LayerView: View {
  let layer: CatalogLayerModel
  let phaseCount: Int
  @Binding var selection: Int
  @EnvironmentObject private var viewModel: ContentViewModel
  @State private var showPageIndicator = false
  @State private var hideIndicatorTask: Task<Void, Never>?

  var body: some View {
    TabView(selection: $selection) {
      ForEach(0 ..< (phaseCount + 2), id: \.self) { index in
        if phaseCount == 0 { EmptyView() }
        else {
          let normalized = (index + phaseCount - 1) % phaseCount
          let phase = layer.phases[normalized]
          PhasePageView(
            layer: layer,
            phase: phase,
            color: Color(stage: layer.color)
          )
          .tag(index)
        }
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .onChange(of: selection) { _, newValue in
      guard phaseCount > 0 else { return }
      let adjusted = PhaseNavigator.adjustedSelection(newValue, phaseCount: phaseCount)
      if adjusted != newValue {
        selection = adjusted
      }
      let normalized = PhaseNavigator.normalizedIndex(adjusted, phaseCount: phaseCount)
      viewModel.selectedPhaseIndex = normalized
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
        let normalized = PhaseNavigator.normalizedIndex(selection, phaseCount: phaseCount)
        let isSelected = index == normalized
        Circle()
          .fill(isSelected ? Color.white : Color.white.opacity(0.3))
          .frame(width: isSelected ? 6 : 4, height: isSelected ? 6 : 4)
          .animation(.easeInOut(duration: 0.2), value: selection)
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

struct PhasePageView: View {
  let layer: CatalogLayerModel
  let phase: CatalogPhaseModel
  let color: Color

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Background - non-tappable
        VStack(spacing: 0) {
          // Top gutter for vertical scroll
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

        // Small tappable navigation button - bottom right
        VStack {
          Spacer()
          HStack {
            Spacer()
            NavigationLink(destination: destinationView) {
              Image(systemName: "chevron.right.circle.fill")
                .foregroundColor(.white.opacity(0.8))
                .font(.title2)
                .background(
                  Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: 32, height: 32)
                )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 12)
          }
          .padding(.bottom, 20)
        }
      }
    }
  }

  @ViewBuilder private var destinationView: some View {
    if layer.id == 0 {
      StrategyListView(phase: phase, color: color)
    } else {
      CurriculumDetailView(layer: layer, phase: phase, color: color)
    }
  }
}

struct StrategyListView: View {
  let phase: CatalogPhaseModel
  let color: Color
  @EnvironmentObject private var viewModel: ContentViewModel
  @EnvironmentObject private var flowCoordinator: FlowCoordinator
  @Environment(\.isShowingDetailView) private var isShowingDetailView
  @State private var showingJournalConfirmation = false
  @State private var selectedStrategy: CatalogStrategyModel?

  // For strategies-only phases, find a curriculum ID from any available layer/phase
  private var fallbackCurriculumID: Int? {
    // First try the current phase
    if let id = phase.medicinal.first?.id ?? phase.toxic.first?.id {
      return id
    }

    // For strategies-only layers (layer 0), find any curriculum entry from other layers
    // This allows logging strategies against the first available curriculum entry
    for layer in viewModel.layers {
      if layer.id != 0 { // Skip the strategies layer itself
        for layerPhase in layer.phases {
          if let id = layerPhase.medicinal.first?.id ?? layerPhase.toxic.first?.id {
            return id
          }
        }
      }
    }

    return nil
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 4) {
        Text(phase.name)
          .font(.title2)
          .fontWeight(.thin)
          .foregroundColor(.white)
          .padding(.top, 8)
          .padding(.bottom, 12)

        LazyVStack(spacing: 8) {
          ForEach(phase.strategies) { item in
            ZStack(alignment: .topTrailing) {
              HStack {
                Circle()
                  .fill(Color(stage: item.color))
                  .frame(width: 6, height: 6)
                  .shadow(color: Color(stage: item.color), radius: 2)
                Text(item.strategy)
                  .font(.body)
                  .foregroundColor(.white)
                  .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 24)
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 10)
              .background(
                RoundedRectangle(cornerRadius: 8)
                  .fill(color.opacity(0.1))
              )
              .onTapGesture {
                if fallbackCurriculumID != nil {
                  selectedStrategy = item
                  showingJournalConfirmation = true
                }
              }

              if fallbackCurriculumID != nil {
                MysticalJournalIcon(color: color)
                  .padding(.top, 8)
                  .padding(.trailing, 12)
                  .onTapGesture {
                    selectedStrategy = item
                    showingJournalConfirmation = true
                  }
              }
            }
          }
        }
        .padding(.horizontal, 8)
      }
      .padding(.vertical, 16)
    }
    .background(
      LinearGradient(
        gradient: Gradient(colors: [Color.black, Color.black.opacity(0.8)]),
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .alert("Log Strategy", isPresented: $showingJournalConfirmation) {
      Button("Yes") {
        handleLogAction()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Would you like to log \"\(selectedStrategy?.strategy ?? "")\"?")
    }
    .onAppear {
      isShowingDetailView.wrappedValue = true
    }
    .onDisappear {
      isShowingDetailView.wrappedValue = false
    }
  }

  private func handleLogAction() {
    if flowCoordinator.currentStep == .selectingStrategy {
      flowCoordinator.captureStrategy(selectedStrategy)
    } else {
      if let curriculumID = fallbackCurriculumID, let strategy = selectedStrategy {
        Task {
          await viewModel.journal(
            curriculumID: curriculumID,
            strategyID: strategy.id
          )
        }
      }
    }
  }
}

struct CurriculumDetailView: View {
  let layer: CatalogLayerModel
  let phase: CatalogPhaseModel
  let color: Color
  @EnvironmentObject private var viewModel: ContentViewModel
  @EnvironmentObject private var flowCoordinator: FlowCoordinator
  @Environment(\.isShowingDetailView) private var isShowingDetailView

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        Text(phase.name)
          .font(.title2)
          .fontWeight(.thin)
          .foregroundColor(.white)
          .padding(.top, 8)

        VStack(spacing: 20) {
          ForEach(phase.medicinal) { entry in
            CurriculumCard(
              title: "MEDICINE",
              expression: entry.expression,
              accent: color,
              actionTitle: "Log Medicinal",
              entry: entry
            )
          }

          ForEach(phase.toxic) { entry in
            CurriculumCard(
              title: "TOXIC",
              expression: entry.expression,
              accent: .red,
              actionTitle: "Log Toxic",
              entry: entry
            )
          }
        }
        .padding(.horizontal, 8)

        if !phase.strategies.isEmpty {
          VStack(alignment: .leading, spacing: 12) {
            Text("STRATEGIES")
              .font(.caption)
              .foregroundColor(.white.opacity(0.7))
              .tracking(1.5)
            ForEach(phase.strategies) { strategy in
              StrategyCard(
                strategy: strategy,
                color: color,
                phase: phase
              )
            }
          }
          .padding(.horizontal, 16)
        }
      }
      .padding(.vertical, 16)
    }
    .background(
      LinearGradient(
        gradient: Gradient(colors: [Color.black, Color.black.opacity(0.8)]),
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .onAppear {
      isShowingDetailView.wrappedValue = true
    }
    .onDisappear {
      isShowingDetailView.wrappedValue = false
    }
  }
}

private struct CurriculumCard: View {
  let title: String
  let expression: String
  let accent: Color
  let actionTitle: String
  let entry: CatalogCurriculumEntryModel
  @EnvironmentObject private var viewModel: ContentViewModel
  @EnvironmentObject private var flowCoordinator: FlowCoordinator
  @State private var showingJournalConfirmation = false

  var body: some View {
    ZStack(alignment: .topTrailing) {
      VStack(alignment: .leading, spacing: 8) {
        Text(title)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(.white.opacity(0.7))
          .tracking(1.5)

        Text(expression)
          .font(.body)
          .fontWeight(.medium)
          .foregroundColor(accent)
          .padding(.trailing, 20)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(
            LinearGradient(
              gradient: Gradient(colors: [accent.opacity(0.3), accent.opacity(0.1)]),
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(accent.opacity(0.5), lineWidth: 0.5)
          )
      )
      .onTapGesture {
        showingJournalConfirmation = true
      }

      MysticalJournalIcon(color: accent)
        .padding(.top, 8)
        .padding(.trailing, 12)
        .onTapGesture {
          showingJournalConfirmation = true
        }
    }
    .alert("Log \(title.capitalized)", isPresented: $showingJournalConfirmation) {
      Button("Yes") {
        handleLogAction()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Would you like to log \"\(expression)\"?")
    }
  }

  private func handleLogAction() {
    switch flowCoordinator.currentStep {
    case .selectingPrimary:
      flowCoordinator.capturePrimary(entry)
    case .selectingSecondary:
      flowCoordinator.captureSecondary(entry)
    default:
      // Normal mode: immediate logging
      Task { await viewModel.journal(curriculumID: entry.id) }
    }
  }
}

struct MysticalJournalIcon: View {
  let color: Color
  @State private var isGlowing = false

  var body: some View {
    ZStack {
      Circle()
        .strokeBorder(
          color.opacity(isGlowing ? 0.6 : 0.3),
          lineWidth: 1.0
        )
        .frame(width: 14, height: 14)
        .shadow(
          color: color.opacity(isGlowing ? 0.4 : 0.2),
          radius: isGlowing ? 2 : 1
        )

      Image(systemName: "plus")
        .font(.system(size: 8, weight: .medium))
        .foregroundColor(color.opacity(isGlowing ? 0.9 : 0.6))
    }
    .scaleEffect(isGlowing ? 1.1 : 1.0)
    .animation(
      .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
      value: isGlowing
    )
    .onAppear {
      isGlowing = true
    }
  }
}

struct StrategyCard: View {
  let strategy: CatalogStrategyModel
  let color: Color
  let phase: CatalogPhaseModel
  @EnvironmentObject private var viewModel: ContentViewModel
  @EnvironmentObject private var flowCoordinator: FlowCoordinator
  @State private var showingJournalConfirmation = false

  var body: some View {
    ZStack(alignment: .topTrailing) {
      HStack {
        Circle()
          .fill(Color(stage: strategy.color))
          .frame(width: 6, height: 6)
          .shadow(color: Color(stage: strategy.color), radius: 2)
        Text(strategy.strategy)
          .font(.footnote)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity, alignment: .leading)
        Spacer(minLength: 20)
      }
      .padding(8)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(color.opacity(0.08))
      )
      .onTapGesture {
        let primaryID = phase.medicinal.first?.id ?? phase.toxic.first?.id
        if primaryID != nil || flowCoordinator.currentStep == .selectingStrategy {
          showingJournalConfirmation = true
        }
      }

      let primaryID = phase.medicinal.first?.id ?? phase.toxic.first?.id
      if primaryID != nil || flowCoordinator.currentStep == .selectingStrategy {
        MysticalJournalIcon(color: color)
          .padding(.top, 6)
          .padding(.trailing, 8)
          .onTapGesture {
            showingJournalConfirmation = true
          }
      }
    }
    .alert("Log Strategy", isPresented: $showingJournalConfirmation) {
      Button("Yes") {
        handleLogAction()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Would you like to log \"\(strategy.strategy)\"?")
    }
  }

  private func handleLogAction() {
    if flowCoordinator.currentStep == .selectingStrategy {
      flowCoordinator.captureStrategy(strategy)
    } else {
      let primaryID = phase.medicinal.first?.id ?? phase.toxic.first?.id
      if let primaryID {
        Task {
          await viewModel.journal(
            curriculumID: primaryID,
            strategyID: strategy.id
          )
        }
      }
    }
  }
}

// MARK: - Menu Views

struct MenuView: View {
  let journalClient: JournalClientProtocol
  @EnvironmentObject private var viewModel: ContentViewModel
  @EnvironmentObject private var flowCoordinator: FlowCoordinator
  @State private var showingStartPrompt = false

  var body: some View {
    List {
      // Log Emotion uses sheet presentation for modal flow
      // (other menu items use NavigationLink for settings navigation)
      Button {
        // Guard: Ensure catalog hasn't been cleared between button tap and sheet presentation
        if viewModel.layers.count > 0 {
          showingStartPrompt = true
        }
      } label: {
        Label("Log Emotion", systemImage: "heart.text.square")
      }
      .disabled(viewModel.layers.count == 0)
      .accessibilityLabel("Log your current emotion")
      .accessibilityHint("Opens emotion logging flow")

      NavigationLink(destination: ScheduleSettingsView()) {
        Label("Schedules", systemImage: "clock")
      }

      NavigationLink(destination: AnalyticsView()) {
        Label("Analytics", systemImage: "chart.bar")
      }

      NavigationLink(destination: ConceptExplainerView()) {
        Label("About Archetypal Wavelength", systemImage: "book")
      }
    }
    .navigationTitle("Menu")
    .navigationBarTitleDisplayMode(.inline)
    .alert("Select your primary emotion", isPresented: $showingStartPrompt) {
      Button("Continue") {
        flowCoordinator.startPrimarySelection()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Navigate to any emotion and tap to log it.")
    }
  }
}

struct AnalyticsView: View {
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "chart.bar.fill")
        .font(.system(size: 48))
        .foregroundColor(.blue.opacity(0.6))

      Text("Analytics")
        .font(.title2)
        .fontWeight(.thin)

      Text("Coming Soon")
        .font(.caption)
        .foregroundColor(.secondary)

      Text("View your journal history, patterns, and insights.")
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
    .padding()
  }
}

struct ConceptExplainerView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Archetypal Wavelength")
          .font(.title2)
          .fontWeight(.bold)

        Text("The Archetypal Wavelength is a framework for understanding emotional and developmental patterns.")
          .font(.body)

        Group {
          Text("Layers")
            .font(.headline)
            .padding(.top, 8)

          Text("Each color represents a developmental stage, from Beige (survival) through Purple (tribal), Red (power), and beyond.")
            .font(.caption)
        }

        Group {
          Text("Phases")
            .font(.headline)
            .padding(.top, 8)

          Text("Each layer cycles through phases: Rising, Peaking, Falling, Recovering, Integrating, and Embodying.")
            .font(.caption)
        }

        Group {
          Text("Dosages")
            .font(.headline)
            .padding(.top, 8)

          Text("Each feeling exists in two forms:")
            .font(.caption)

          Text("• Medicinal: The healthy expression")
            .font(.caption)
            .padding(.leading)

          Text("• Toxic: The shadow or excessive form")
            .font(.caption)
            .padding(.leading)
        }

        Group {
          Text("Self-Care Strategies")
            .font(.headline)
            .padding(.top, 8)

          Text("Each phase has specific strategies to help you navigate that emotional territory with grace.")
            .font(.caption)
        }
      }
      .padding()
    }
    .navigationTitle("About")
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - Flow Review Sheet

struct FlowReviewSheet: View {
  @ObservedObject var flowCoordinator: FlowCoordinator
  @State private var isSubmitting = false
  @State private var showingSuccess = false
  @State private var showingError = false
  @State private var errorMessage = ""

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          Text("Review Your Entry")
            .font(.title3)
            .fontWeight(.semibold)
            .padding(.top)

          if let primary = flowCoordinator.selections.primary {
            emotionCard(
              label: "Primary Emotion",
              expression: primary.expression,
              dosage: primary.dosage
            )
          }

          if let secondary = flowCoordinator.selections.secondary {
            emotionCard(
              label: "Secondary Emotion",
              expression: secondary.expression,
              dosage: secondary.dosage
            )
          }

          if let strategy = flowCoordinator.selections.strategy {
            strategyCard(strategy: strategy)
          }

          Button {
            submitEntry()
          } label: {
            if isSubmitting {
              ProgressView()
            } else {
              Text("Submit Entry")
                .fontWeight(.semibold)
            }
          }
          .disabled(isSubmitting)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(isSubmitting ? Color.gray : Color.blue)
          .foregroundColor(.white)
          .cornerRadius(10)
          .padding(.horizontal)
        }
        .padding()
      }
      .navigationTitle("Review")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            flowCoordinator.cancel()
          }
          .disabled(isSubmitting)
        }
      }
      .alert("Success", isPresented: $showingSuccess) {
        Button("OK") {
          flowCoordinator.cancel()
        }
      } message: {
        Text("Your journal entry has been saved.")
      }
      .alert("Error", isPresented: $showingError) {
        Button("Retry") {
          submitEntry()
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text(errorMessage)
      }
    }
  }

  @ViewBuilder
  private func emotionCard(label: String, expression: String, dosage: CatalogDosage) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(label)
        .font(.caption)
        .foregroundColor(.secondary)
        .textCase(.uppercase)

      HStack {
        Circle()
          .fill(dosage == .medicinal ? Color.green : Color.red)
          .frame(width: 10, height: 10)

        Text(expression)
          .font(.body)
          .fontWeight(.medium)

        Spacer()

        Text(dosage == .medicinal ? "Medicinal" : "Toxic")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(Color.secondary.opacity(0.1))
    .cornerRadius(10)
  }

  @ViewBuilder
  private func strategyCard(strategy: CatalogStrategyModel) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Strategy")
        .font(.caption)
        .foregroundColor(.secondary)
        .textCase(.uppercase)

      HStack {
        Circle()
          .fill(Color(stage: strategy.color))
          .frame(width: 10, height: 10)

        Text(strategy.strategy)
          .font(.body)
          .fontWeight(.medium)

        Spacer()
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(Color.secondary.opacity(0.1))
    .cornerRadius(10)
  }

  private func submitEntry() {
    isSubmitting = true
    Task {
      do {
        try await flowCoordinator.submit()
        isSubmitting = false
        showingSuccess = true
      } catch {
        isSubmitting = false
        errorMessage = "Failed to submit: \(error.localizedDescription)"
        showingError = true
      }
    }
  }
}

#Preview {
  ContentView()
}
