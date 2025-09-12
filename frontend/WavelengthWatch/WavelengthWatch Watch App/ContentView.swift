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
      "title": "Self-Care Strategies",
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
    VStack {
      Text("Medicine: \(entry.medicine)")
      Text("Toxic: \(entry.toxic)")
    }
    .foregroundColor(color)
    .navigationTitle(phase.rawValue)
  }
}

struct StrategyListView: View {
  let phase: Phase
  let strategies: [Strategy]

  var body: some View {
    List(strategies) { item in
      Text(item.strategy)
        .foregroundColor(Color(stage: item.color))
    }
    .navigationTitle(phase.rawValue)
  }
}

struct PhasePageView: View {
  let phase: Phase
  let header: LayerHeader?
  let content: PhaseContent
  let color: Color

  var body: some View {
    VStack {
      if let header {
        Text(header.title)
          .font(.headline)
        Text(header.subtitle)
          .font(.subheadline)
      }
      NavigationLink(destination: destinationView) {
        Text(phase.rawValue)
          .font(.title2)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .tint(color)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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

  @State private var selection = 0
  private let phases = Phase.allCases

  var body: some View {
    TabView(selection: $selection) {
      ForEach(0 ..< (phases.count + 1), id: \.self) { index in
        let phase = phases[index % phases.count]
        let content: PhaseContent = if layer == "Strategies" {
          .strategies(strategiesData[phase] ?? [])
        } else if let entry = curriculum[phase] {
          .curriculum(entry)
        } else {
          .curriculum(CurriculumEntry(medicine: "", toxic: ""))
        }
        PhasePageView(
          phase: phase,
          header: header,
          content: content,
          color: Color(stage: layer)
        )
        .tag(index)
      }
    }
    .tabViewStyle(.page)
    .onChange(of: selection) { newValue in
      if newValue == phases.count {
        selection = 0
      }
    }
  }
}

struct ContentView: View {
  @State private var layerSelection = 0
  private let layers = [
    "Strategies", "Beige", "Purple", "Red", "Blue", "Orange", "Green", "Yellow", "Teal",
    "Ultraviolet",
  ]
  private let strategies = StrategyData.load()
  private let headers = HeaderData.load()
  private let curriculum = CurriculumData.load()

  var body: some View {
    NavigationStack {
      TabView(selection: $layerSelection) {
        ForEach(0 ..< layers.count, id: \.self) { index in
          let layer = layers[index]
          LayerView(
            layer: layer,
            header: headers[layer],
            strategiesData: strategies,
            curriculum: curriculum[layer] ?? [:]
          )
          .tag(index)
          .rotationEffect(.degrees(90))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
      .tabViewStyle(.page)
      .rotationEffect(.degrees(-90))
    }
  }
}

#Preview {
  ContentView()
}
