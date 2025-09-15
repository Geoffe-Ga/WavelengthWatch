//
//  ContentView.swift
//  WavelengthWatch Watch App
//
//  Created by Geoff Gallinger on 9/10/25.
//

import SwiftUI

struct Strategy: Identifiable, Decodable {
  private let strategyId: Int?
  let color: String
  let strategy: String

  var id: Int { strategyId ?? strategy.hashValue }

  private enum CodingKeys: String, CodingKey {
    case strategyId = "id"
    case color
    case strategy
  }
}

struct LayerHeader: Decodable {
  let title: String
  let subtitle: String
}

struct CurriculumEntry: Decodable {
  let medicine: String
  let toxic: String

  private enum CodingKeys: String, CodingKey {
    case medicine = "Medicine"
    case toxic = "Toxic"
  }
}

enum Phase: String, CaseIterable, Identifiable {
  case Rising
  case Peaking
  case Withdrawal
  case Diminishing
  case BottomingOut = "Bottoming Out"
  case Restoration

  var id: String { rawValue }
}

enum StrategyData {
  static func load() -> [Phase: [Strategy]] {
    JSONDataLoader.loadStrategies()
  }
}

enum HeaderData {
  static func load() -> [String: LayerHeader] {
    JSONDataLoader.loadHeaders()
  }
}

enum CurriculumData {
  static func load() -> [String: [Phase: CurriculumEntry]] {
    JSONDataLoader.loadCurriculum()
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

enum PhaseContent {
  case strategies([Strategy])
  case curriculum(CurriculumEntry)
}

struct CurriculumDetailView: View {
  let phase: Phase
  let entry: CurriculumEntry
  let color: Color

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        Text(phase.rawValue)
          .font(.title2)
          .fontWeight(.thin)
          .foregroundColor(.white)
          .padding(.top, 8)

        VStack(spacing: 20) {
          // Medicine Card
          VStack(alignment: .leading, spacing: 8) {
            Text("MEDICINE")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundColor(.white.opacity(0.7))
              .tracking(1.5)

            Text(entry.medicine)
              .font(.body)
              .fontWeight(.medium)
              .foregroundColor(color)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(
                LinearGradient(
                  gradient: Gradient(colors: [color.opacity(0.3), color.opacity(0.1)]),
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(color.opacity(0.5), lineWidth: 0.5)
              )
          )

          // Toxic Card
          VStack(alignment: .leading, spacing: 8) {
            Text("TOXIC")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundColor(.white.opacity(0.7))
              .tracking(1.5)

            Text(entry.toxic)
              .font(.body)
              .fontWeight(.medium)
              .foregroundColor(.red.opacity(0.9))
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(
                LinearGradient(
                  gradient: Gradient(colors: [Color.red.opacity(0.3), Color.red.opacity(0.1)]),
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(Color.red.opacity(0.5), lineWidth: 0.5)
              )
          )
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

struct StrategyListView: View {
  let phase: Phase
  let strategies: [Strategy]

  var body: some View {
    ScrollView {
      VStack(spacing: 4) {
        Text(phase.rawValue)
          .font(.title2)
          .fontWeight(.thin)
          .foregroundColor(.white)
          .padding(.top, 8)
          .padding(.bottom, 12)

        LazyVStack(spacing: 8) {
          ForEach(strategies) { item in
            HStack {
              Circle()
                .fill(Color(stage: item.color))
                .frame(width: 6, height: 6)
                .shadow(color: Color(stage: item.color), radius: 2, x: 0, y: 0)

              Text(item.strategy)
                .font(.body)
                .fontWeight(.regular)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(
                  LinearGradient(
                    gradient: Gradient(colors: [
                      Color(stage: item.color).opacity(0.25),
                      Color(stage: item.color).opacity(0.08),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                  )
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(stage: item.color).opacity(0.35), lineWidth: 0.5)
                )
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

struct PhasePageView: View {
  let phase: Phase
  let header: LayerHeader?
  let content: PhaseContent
  let color: Color

  var body: some View {
    VStack(spacing: 0) {
      // Header section
      if let header {
        VStack(spacing: 4) {
          Text(header.title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white.opacity(0.9))
            .tracking(2.0)
            .multilineTextAlignment(.center)

          Text(header.subtitle)
            .font(.caption2)
            .fontWeight(.regular)
            .foregroundColor(.white.opacity(0.6))
            .tracking(1.0)
            .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
      }

      // Main phase button fills remaining space
      VStack {
        NavigationLink(destination: destinationView) {
          VStack(spacing: 6) {
            Text(phase.rawValue)
              .font(.title3)
              .fontWeight(.medium)
              .foregroundColor(.white)
              .multilineTextAlignment(.center)
              .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 2)

            // Subtle indicator
            RoundedRectangle(cornerRadius: 2)
              .fill(color)
              .frame(width: 24, height: 2)
              .shadow(color: color, radius: 3, x: 0, y: 0)
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
        .buttonStyle(PlainButtonStyle())
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
        // Subtle mystical overlay
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
    switch content {
    case let .strategies(strategies):
      StrategyListView(phase: phase, strategies: strategies)
    case let .curriculum(entry):
      CurriculumDetailView(phase: phase, entry: entry, color: color)
    }
  }
}

struct LayerView: View {
  let layer: String
  let header: LayerHeader?
  let strategiesData: [Phase: [Strategy]]
  let curriculum: [Phase: CurriculumEntry]
  /// Binding to the globally selected phase so that phase choice
  /// persists across color layers.
  @Binding var selection: Int
  @State private var showPageIndicator = false
  @State private var hideIndicatorTask: Task<Void, Never>?
  private let phases = Phase.allCases

  private func getPhaseContent(for phase: Phase) -> PhaseContent {
    if layer == "Strategies" {
      .strategies(strategiesData[phase] ?? [])
    } else if let entry = curriculum[phase] {
      .curriculum(entry)
    } else {
      .curriculum(CurriculumEntry(medicine: "", toxic: ""))
    }
  }

  var body: some View {
    TabView(selection: $selection) {
      ForEach(0 ..< (phases.count + 2), id: \.self) { index in
        let phase = phases[(index + phases.count - 1) % phases.count]
        let content = getPhaseContent(for: phase)
        PhasePageView(
          phase: phase,
          header: header,
          content: content,
          color: Color(stage: layer)
        )
        .tag(index)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .onChange(of: selection) { newValue in
      let adjusted = PhaseNavigator.adjustedSelection(newValue, phaseCount: phases.count)
      if adjusted != newValue {
        selection = adjusted
      }

      // Show indicator when scrolling
      withAnimation(.easeIn(duration: 0.2)) {
        showPageIndicator = true
      }

      // Cancel previous hide task
      hideIndicatorTask?.cancel()

      // Hide after delay
      hideIndicatorTask = Task {
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        if !Task.isCancelled {
          withAnimation(.easeOut(duration: 0.3)) {
            showPageIndicator = false
          }
        }
      }
    }
    .overlay(alignment: .bottom) {
      if showPageIndicator {
        HStack(spacing: 4) {
          ForEach(0 ..< phases.count, id: \.self) { index in
            let selectedIndex = PhaseNavigator.normalizedIndex(selection, phaseCount: phases.count)
            let isSelected = index == selectedIndex
            Circle()
              .fill(isSelected ? Color.white : Color.white.opacity(0.3))
              .frame(
                width: isSelected ? 6 : 4,
                height: isSelected ? 6 : 4
              )
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
        .transition(.opacity)
      }
    }
    .onAppear {
      // Show indicator briefly on appear
      withAnimation(.easeIn(duration: 0.2)) {
        showPageIndicator = true
      }

      hideIndicatorTask = Task {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        if !Task.isCancelled {
          withAnimation(.easeOut(duration: 0.3)) {
            showPageIndicator = false
          }
        }
      }
    }
  }
}

struct ContentView: View {
  @State private var layerSelection = 0
  /// Shared phase selection so swiping between layers retains the
  /// current phase.
  @State private var phaseSelection = 1
  @State private var showLayerIndicator = false
  @State private var hideIndicatorTask: Task<Void, Never>?
  private let layers = [
    "Strategies", "Beige", "Purple", "Red", "Blue", "Orange", "Green", "Yellow", "Teal",
    "Ultraviolet",
  ]
  private let strategies = StrategyData.load()
  private let headers = HeaderData.load()
  private let curriculum = CurriculumData.load()

  var body: some View {
    NavigationStack {
      ZStack {
        TabView(selection: $layerSelection) {
          ForEach(0 ..< layers.count, id: \.self) { index in
            let layer = layers[index]
            LayerView(
              layer: layer,
              header: headers[layer],
              strategiesData: strategies,
              curriculum: curriculum[layer] ?? [:],
              selection: $phaseSelection
            )
            .tag(index)
            .rotationEffect(.degrees(90))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .rotationEffect(.degrees(-90))
        .onChange(of: layerSelection) { _ in
          // Show indicator when scrolling
          withAnimation(.easeIn(duration: 0.2)) {
            showLayerIndicator = true
          }

          // Cancel previous hide task
          hideIndicatorTask?.cancel()

          // Hide after delay
          hideIndicatorTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            if !Task.isCancelled {
              withAnimation(.easeOut(duration: 0.3)) {
                showLayerIndicator = false
              }
            }
          }
        }

        // Custom vertical scroll bar indicator
        if showLayerIndicator {
          GeometryReader { geometry in
            VStack {
              Spacer()
              HStack {
                Spacer()
                ZStack(alignment: .top) {
                  // Background track
                  Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 4, height: geometry.size.height * 0.4)

                  // Progress indicator with layer color
                  Capsule()
                    .fill(
                      LinearGradient(
                        gradient: Gradient(colors: [
                          Color(stage: layers[layerSelection]),
                          Color(stage: layers[layerSelection]).opacity(0.6),
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                      )
                    )
                    .frame(width: 6, height: max(20, (geometry.size.height * 0.4) / CGFloat(layers.count)))
                    .overlay(
                      Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    )
                    .shadow(color: Color(stage: layers[layerSelection]), radius: 3, x: 0, y: 0)
                    .offset(y: CGFloat(layers.count - 1 - layerSelection) * ((geometry.size.height * 0.4 - 20) / CGFloat(layers.count - 1)))
                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: layerSelection)
                }
                .padding(.trailing, 6)
              }
              Spacer()
            }
          }
          .transition(.opacity)
        }
      }
      .onAppear {
        // Show indicator briefly on appear
        withAnimation(.easeIn(duration: 0.2)) {
          showLayerIndicator = true
        }

        hideIndicatorTask = Task {
          try? await Task.sleep(nanoseconds: 2_000_000_000)
          if !Task.isCancelled {
            withAnimation(.easeOut(duration: 0.3)) {
              showLayerIndicator = false
            }
          }
        }
      }
    }
  }
}

#Preview {
  ContentView()
}
