import SwiftUI

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
  @State private var layerSelection: Int
  @State private var phaseSelection: Int
  @State private var showLayerIndicator = false
  @State private var hideIndicatorTask: Task<Void, Never>?

  init() {
    let configuration = AppConfiguration()
    let apiClient = APIClient(baseURL: configuration.apiBaseURL)
    let repository = CatalogRepository(
      remote: CatalogAPIService(apiClient: apiClient),
      cache: FileCatalogCacheStore()
    )
    let journalClient = JournalClient(apiClient: apiClient)
    let initialLayer = UserDefaults.standard.integer(forKey: "selectedLayerIndex")
    let initialPhase = UserDefaults.standard.integer(forKey: "selectedPhaseIndex")
    let model = ContentViewModel(
      repository: repository,
      journalClient: journalClient,
      initialLayerIndex: initialLayer,
      initialPhaseIndex: initialPhase
    )
    _viewModel = StateObject(wrappedValue: model)
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
      .padding(.vertical, 4)
      .task { await viewModel.loadCatalog() }
      .onChange(of: viewModel.phaseOrder) { _ in
        adjustPhaseSelection()
      }
      .onChange(of: layerSelection) { newValue in
        viewModel.selectedLayerIndex = newValue
        storedLayerIndex = newValue
        showLayerIndicator = true
        scheduleLayerIndicatorHide()
      }
      .onChange(of: viewModel.selectedLayerIndex) { newValue in
        if layerSelection != newValue {
          layerSelection = newValue
        }
      }
      .onChange(of: phaseSelection) { newValue in
        guard viewModel.phaseOrder.count > 0 else { return }
        let adjusted = PhaseNavigator.adjustedSelection(newValue, phaseCount: viewModel.phaseOrder.count)
        if adjusted != newValue {
          phaseSelection = adjusted
        }
        let normalized = PhaseNavigator.normalizedIndex(adjusted, phaseCount: viewModel.phaseOrder.count)
        viewModel.selectedPhaseIndex = normalized
        storedPhaseIndex = normalized
      }
      .onChange(of: viewModel.selectedPhaseIndex) { newValue in
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
    }
    .environmentObject(viewModel)
  }

  private var layeredContent: some View {
    GeometryReader { geometry in
      TabView(selection: $layerSelection) {
        ForEach(viewModel.layers.indices, id: \.self) { index in
          let layer = viewModel.layers[index]
          LayerView(
            layer: layer,
            phaseCount: viewModel.phaseOrder.count,
            selection: $phaseSelection
          )
          .tag(index)
          .rotationEffect(.degrees(90))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .rotationEffect(.degrees(-90))
      .overlay(alignment: .trailing) {
        if showLayerIndicator {
          layerIndicator(in: geometry.size)
            .transition(.opacity)
        }
      }
      .onAppear {
        showLayerIndicator = true
        scheduleLayerIndicatorHide()
      }
    }
  }

  private func layerIndicator(in size: CGSize) -> some View {
    let index = min(layerSelection, max(viewModel.layers.count - 1, 0))
    VStack {
      Spacer()
      ZStack(alignment: .top) {
        Capsule()
          .fill(Color.white.opacity(0.1))
          .frame(width: 4, height: size.height * 0.4)
        Capsule()
          .fill(
            LinearGradient(
              gradient: Gradient(colors: [
                Color(stage: viewModel.layers[index].color),
                Color(stage: viewModel.layers[index].color).opacity(0.6),
              ]),
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .frame(width: 6, height: max(20, (size.height * 0.4) / CGFloat(max(viewModel.layers.count, 1))))
          .overlay(
            Capsule()
              .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
          )
          .shadow(color: Color(stage: viewModel.layers[index].color), radius: 3)
          .offset(y: offset(for: size.height * 0.4, layerIndex: index))
          .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: index)
      }
      .padding(.trailing, 6)
      Spacer()
    }
  }

  private func offset(for trackHeight: CGFloat, layerIndex: Int? = nil) -> CGFloat {
    guard viewModel.layers.count > 1 else { return 0 }
    let available = trackHeight - 20
    let index = layerIndex ?? layerSelection
    return CGFloat(viewModel.layers.count - 1 - index) * (available / CGFloat(viewModel.layers.count - 1))
  }

  private func adjustPhaseSelection() {
    guard viewModel.phaseOrder.count > 0 else { return }
    let adjusted = PhaseNavigator.adjustedSelection(phaseSelection, phaseCount: viewModel.phaseOrder.count)
    if adjusted != phaseSelection {
      phaseSelection = adjusted
    }
  }

  private func scheduleLayerIndicatorHide() {
    hideIndicatorTask?.cancel()
    hideIndicatorTask = Task {
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      guard !Task.isCancelled else { return }
      await MainActor.run {
        withAnimation(.easeOut(duration: 0.3)) {
          showLayerIndicator = false
        }
      }
    }
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
    .onChange(of: selection) { newValue in
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
      try? await Task.sleep(nanoseconds: 2_000_000_000)
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
    VStack(spacing: 0) {
      VStack(spacing: 4) {
        Text(layer.title)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundColor(.white.opacity(0.9))
          .tracking(2.0)
          .multilineTextAlignment(.center)
        Text(layer.subtitle)
          .font(.caption2)
          .foregroundColor(.white.opacity(0.6))
      }
      .padding(.top, 12)
      .padding(.bottom, 8)

      VStack {
        NavigationLink(destination: destinationView) {
          VStack(spacing: 6) {
            Text(phase.name)
              .font(.title3)
              .fontWeight(.medium)
              .foregroundColor(.white)
              .multilineTextAlignment(.center)
              .shadow(color: color.opacity(0.5), radius: 4)
            RoundedRectangle(cornerRadius: 2)
              .fill(color)
              .frame(width: 24, height: 2)
              .shadow(color: color, radius: 3)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(
                RadialGradient(
                  gradient: Gradient(colors: [
                    color.opacity(0.35),
                    color.opacity(0.15),
                    Color.clear,
                  ]),
                  center: .center,
                  startRadius: 20,
                  endRadius: 80
                )
              )
              .overlay(
                RoundedRectangle(cornerRadius: 16)
                  .stroke(
                    LinearGradient(
                      gradient: Gradient(colors: [
                        color.opacity(0.6),
                        color.opacity(0.2),
                      ]),
                      startPoint: .topLeading,
                      endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                  )
              )
          )
          .scaleEffect(0.95)
        }
        .buttonStyle(.plain)
      }
      .frame(maxHeight: .infinity)
      .padding(.vertical, 8)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      LinearGradient(
        gradient: Gradient(colors: [
          Color.black.opacity(0.9),
          Color.black.opacity(0.7),
          Color.black,
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .overlay(
        RadialGradient(
          gradient: Gradient(colors: [
            color.opacity(0.08),
            Color.clear,
          ]),
          center: .center,
          startRadius: 50,
          endRadius: 150
        )
      )
    )
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
            let primaryID = phase.medicinal.first?.id ?? phase.toxic.first?.id
            HStack {
              Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color, radius: 2)
              Text(item.strategy)
                .font(.body)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
              if let primaryID {
                Button("Log") {
                  Task {
                    await viewModel.journal(
                      curriculumID: primaryID,
                      strategyID: item.id
                    )
                  }
                }
                .buttonStyle(.bordered)
                .tint(color)
              }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
            )
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
  }
}

struct CurriculumDetailView: View {
  let layer: CatalogLayerModel
  let phase: CatalogPhaseModel
  let color: Color
  @EnvironmentObject private var viewModel: ContentViewModel

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
              actionTitle: "Log Medicinal"
            ) {
              Task { await viewModel.journal(curriculumID: entry.id) }
            }
          }

          ForEach(phase.toxic) { entry in
            CurriculumCard(
              title: "TOXIC",
              expression: entry.expression,
              accent: .red,
              actionTitle: "Log Toxic"
            ) {
              Task { await viewModel.journal(curriculumID: entry.id) }
            }
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
              Text(strategy.strategy)
                .font(.footnote)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(
                  RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.08))
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
  }
}

private struct CurriculumCard: View {
  let title: String
  let expression: String
  let accent: Color
  let actionTitle: String
  let action: () -> Void

  var body: some View {
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

      Button(actionTitle, action: action)
        .buttonStyle(.borderedProminent)
        .tint(accent)
        .controlSize(.small)
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
  }
}

#Preview {
  ContentView()
}
