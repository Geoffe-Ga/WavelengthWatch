//
//  ContentView.swift
//  WavelengthWatch Watch App
//
//  Created by Geoff Gallinger on 9/10/25.
//

import SwiftUI

struct Strategy: Identifiable, Decodable {
  let color: String
  let strategy: String
  var id: String { strategy }
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
    let data = Data(strategiesJSON.utf8)
    let decoded = try? JSONDecoder().decode([String: [Strategy]].self, from: data)
    var result: [Phase: [Strategy]] = [:]
    for phase in Phase.allCases {
      result[phase] = decoded?[phase.rawValue] ?? []
    }
    return result
  }

  // Embedded dataset mirrors backend/data/strategies.json.
  // This keeps the watch app self-contained for the MVP.
  private static let strategiesJSON = #"""
  {
    "Rising": [
      {"color": "Beige", "strategy": "Cold Shower"},
      {"color": "Purple", "strategy": "Clairaudient Practice"},
      {"color": "Purple", "strategy": "Divination"},
      {"color": "Purple", "strategy": "Dog Walkin Shamanism"},
      {"color": "Blue", "strategy": "Empathizing with Others"},
      {"color": "Blue", "strategy": "Metta Meditation"},
      {"color": "Blue", "strategy": "Dad Time"},
      {"color": "Orange", "strategy": "Pranayama (Wim Hof)"},
      {"color": "Orange", "strategy": "Eating Something Tasty"},
      {"color": "Orange", "strategy": "Pranayama (Alternate Nostril)"},
      {"color": "Green", "strategy": "Yoga"},
      {"color": "Green", "strategy": "Creative Writing"},
      {"color": "Green", "strategy": "Making Music"},
      {"color": "Teal", "strategy": "Meditation Micro-Retreats"}
    ],
    "Peaking": [
      {"color": "Red", "strategy": "Confidence Practice"},
      {"color": "Blue", "strategy": "Socializing"},
      {"color": "Blue", "strategy": "Compassion Practice"},
      {"color": "Yellow", "strategy": "Samatha Vipassana"},
      {"color": "Yellow", "strategy": "Kombucha"},
      {"color": "Teal", "strategy": "Magick"},
      {"color": "Ultraviolet", "strategy": "Meditation Retreats"}
    ],
    "Withdrawal": [
      {"color": "Beige", "strategy": "Eating Something Grounding"},
      {"color": "Blue", "strategy": "Spending Time in Crowded Places"},
      {"color": "Blue", "strategy": "I Belong Here Ritual"},
      {"color": "Blue", "strategy": "Clairsentient Practice with Loved Ones"},
      {"color": "Orange", "strategy": "Intense Exercise"},
      {"color": "Orange", "strategy": "Pranayama (4/7/8)"},
      {"color": "Orange", "strategy": "Pranayama (Box Breathing)"},
      {"color": "Beige", "strategy": "5-4-3-2-1 Technique"},
      {"color": "Yellow", "strategy": "Anti-Anxiety Meds"}
    ],
    "Diminishing": [
      {"color": "Purple", "strategy": "Long Drives"},
      {"color": "Purple", "strategy": "Hot Beverages"},
      {"color": "Red", "strategy": "Walking"},
      {"color": "Green", "strategy": "Journaling"},
      {"color": "Green", "strategy": "Cleaning"}
    ],
    "Bottoming Out": [
      {"color": "Beige", "strategy": "Readjusting posture"},
      {"color": "Beige", "strategy": "Getting Comfy"},
      {"color": "Beige", "strategy": "Drinking Water"},
      {"color": "Purple", "strategy": "Listening to Music"},
      {"color": "Red", "strategy": "Pranayama (Lion's Breath)"},
      {"color": "Orange", "strategy": "Learning"},
      {"color": "Teal", "strategy": "Baby Waterfall Conventions"}
    ],
    "Restoration": [
      {"color": "Beige", "strategy": "One Pushup / One Squat"},
      {"color": "Beige", "strategy": "Wash face"},
      {"color": "Purple", "strategy": "Kirtan"},
      {"color": "Purple", "strategy": "Taking a Bath"},
      {"color": "Purple", "strategy": "Getting Some Sunshine"},
      {"color": "Red", "strategy": "Somatic Meditation"},
      {"color": "Red", "strategy": "Biking"},
      {"color": "Red", "strategy": "Jogging"},
      {"color": "Red", "strategy": "Dancing"},
      {"color": "Blue", "strategy": "Husband Time"}
    ]
  }
  """#
}

enum HeaderData {
  static func load() -> [String: LayerHeader] {
    let data = Data(headersJSON.utf8)
    let decoded = try? JSONDecoder().decode([String: LayerHeader].self, from: data)
    return decoded ?? [:]
  }

  // Embedded dataset mirrors backend/data/headers.json.
  // This keeps the watch app self-contained for the MVP.
  private static let headersJSON = #"""
  {
    "Beige": {
      "title": "INHABIT",
      "subtitle": "(Do)"
    },
    "Purple": {
      "title": "INHABIT",
      "subtitle": "(Feel)"
    },
    "Red": {
      "title": "EXPRESS",
      "subtitle": "(Do)"
    },
    "Blue": {
      "title": "EXPRESS",
      "subtitle": "(Feel)"
    },
    "Orange": {
      "title": "COLLABORATE",
      "subtitle": "(Do)"
    },
    "Green": {
      "title": "COLLABORATE",
      "subtitle": "(Feel)"
    },
    "Yellow": {
      "title": "INTEGRATE",
      "subtitle": "(Do)"
    },
    "Teal": {
      "title": "INTEGRATE",
      "subtitle": "(Feel)"
    },
    "Ultraviolet": {
      "title": "ABSORB",
      "subtitle": "(Do/Feel)"
    },
    "Clear Light": {
      "title": "BE",
      "subtitle": "(Neither/Both)"
    },
    "Strategies": {
      "title": "SELF-CARE",
      "subtitle": "(For Surfing)"
    }
  }
  """#
}

enum CurriculumData {
  static func load() -> [String: [Phase: CurriculumEntry]] {
    let data = Data(curriculumJSON.utf8)
    let decoded =
      try? JSONDecoder().decode([String: [String: CurriculumEntry]].self, from: data)
    var result: [String: [Phase: CurriculumEntry]] = [:]
    for (layer, phases) in decoded ?? [:] {
      var phaseMap: [Phase: CurriculumEntry] = [:]
      for (phaseName, entry) in phases {
        if let phase = Phase(rawValue: phaseName) {
          phaseMap[phase] = entry
        }
      }
      result[layer] = phaseMap
    }
    return result
  }

  // Embedded dataset mirrors backend/data/curriculum.json.
  // This keeps the watch app self-contained for the MVP.
  private static let curriculumJSON = #"""
  {
    "Beige": {
      "Rising": {"Medicine": "Commitment", "Toxic": "Overcommitment"},
      "Peaking": {"Medicine": "Diligence", "Toxic": "Thriving"},
      "Withdrawal": {"Medicine": "Steadiness", "Toxic": "Burnout"},
      "Diminishing": {"Medicine": "Security", "Toxic": "Grasping"},
      "Bottoming Out": {"Medicine": "Planning", "Toxic": "Overwhelm"},
      "Restoration": {"Medicine": "Next Habit", "Toxic": "New Plan"}
    },
    "Purple": {
      "Rising": {"Medicine": "Inspiration", "Toxic": "Grandiosity"},
      "Peaking": {"Medicine": "Joy", "Toxic": "Ecstasy"},
      "Withdrawal": {"Medicine": "Introspectivity", "Toxic": "Anxiety"},
      "Diminishing": {"Medicine": "Tranquility", "Toxic": "Self-Doubt"},
      "Bottoming Out": {"Medicine": "Convalescence", "Toxic": "Self-Loathing"},
      "Restoration": {"Medicine": "Recuperation", "Toxic": "Selfishness"}
    },
    "Red": {
      "Rising": {"Medicine": "Leading", "Toxic": "Dominating"},
      "Peaking": {"Medicine": "Power-With", "Toxic": "Power-Over"},
      "Withdrawal": {"Medicine": "Stepping Back", "Toxic": "Crumbling"},
      "Diminishing": {"Medicine": "Self-Acceptance", "Toxic": "Shame"},
      "Bottoming Out": {"Medicine": "Following", "Toxic": "Subjugation"},
      "Restoration": {"Medicine": "Assembling", "Toxic": "Revenge"}
    },
    "Blue": {
      "Rising": {"Medicine": "Ambition", "Toxic": "Voraciousness"},
      "Peaking": {"Medicine": "Attunement", "Toxic": "Leprosy"},
      "Withdrawal": {"Medicine": "Discernment", "Toxic": "Self-Medication"},
      "Diminishing": {"Medicine": "Conviction", "Toxic": "Rage"},
      "Bottoming Out": {"Medicine": "Surrender", "Toxic": "Misery"},
      "Restoration": {"Medicine": "Catharsis", "Toxic": "Self-Repression"}
    },
    "Orange": {
      "Rising": {"Medicine": "Hypothesize", "Toxic": "Assert"},
      "Peaking": {"Medicine": "Experiment", "Toxic": "Crusade"},
      "Withdrawal": {"Medicine": "Collect Data", "Toxic": "Overlook Details"},
      "Diminishing": {"Medicine": "Analyze", "Toxic": "Force it"},
      "Bottoming Out": {"Medicine": "Synthesize", "Toxic": "Fail"},
      "Restoration": {"Medicine": "Question", "Toxic": "Presume"}
    },
    "Green": {
      "Rising": {"Medicine": "Connection", "Toxic": "Oversharing"},
      "Peaking": {"Medicine": "Belonging", "Toxic": "Megalomania"},
      "Withdrawal": {"Medicine": "Retirement", "Toxic": "Social Anxiety"},
      "Diminishing": {"Medicine": "Unwinding", "Toxic": "Alienation"},
      "Bottoming Out": {"Medicine": "Repose", "Toxic": "Isolation"},
      "Restoration": {"Medicine": "Vulnerability", "Toxic": "Bitterness"}
    },
    "Yellow": {
      "Rising": {"Medicine": "Rebellion", "Toxic": "Mischief"},
      "Peaking": {"Medicine": "Anarchy", "Toxic": "Chaos"},
      "Withdrawal": {"Medicine": "Organize", "Toxic": "Discord"},
      "Diminishing": {"Medicine": "Establish", "Toxic": "Confusion"},
      "Bottoming Out": {"Medicine": "Order", "Toxic": "Bureaucracy"},
      "Restoration": {"Medicine": "Disintegrate", "Toxic": "The Aftermath"}
    },
    "Teal": {
      "Rising": {"Medicine": "Epiphany", "Toxic": "Delusion"},
      "Peaking": {"Medicine": "Gnosis", "Toxic": "Psychosis"},
      "Withdrawal": {"Medicine": "Receptivity", "Toxic": "Paranoia"},
      "Diminishing": {"Medicine": "Absorption", "Toxic": "Horror"},
      "Bottoming Out": {"Medicine": "Metabolism", "Toxic": "Despair"},
      "Restoration": {"Medicine": "Pattern-Seeking", "Toxic": "Belief Salience"}
    },
    "Ultraviolet": {
      "Rising": {
        "Medicine": "Unification of Mind",
        "Toxic": "Worldly Desire"
      },
      "Peaking": {"Medicine": "Jhana", "Toxic": "Bliss Addiction"},
      "Withdrawal": {
        "Medicine": "Metta and Meditative Joy",
        "Toxic": "Agitation Due to Worry or Remorse"
      },
      "Diminishing": {
        "Medicine": "Sustained Attention",
        "Toxic": "Doubt"
      },
      "Bottoming Out": {"Medicine": "Pleasure", "Toxic": "Aversion"},
      "Restoration": {
        "Medicine": "Directed Attention",
        "Toxic": "Laziness or Lethargy"
      }
    }
  }
  """#
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
    GeometryReader { geometry in
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

        Spacer()

        // Main phase button
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
          .frame(maxWidth: .infinity)
          .frame(height: geometry.size.height * 0.6)
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

        Spacer()
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
    ZStack {
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

      // Custom horizontal page indicator
      if showPageIndicator {
        GeometryReader { geometry in
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
          .position(x: geometry.size.width / 2, y: geometry.size.height - 8)
        }
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
