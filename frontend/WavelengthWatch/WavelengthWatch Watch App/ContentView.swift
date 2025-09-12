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
  let strategies: [Strategy]

  var body: some View {
    VStack {
      if let header {
        Text(header.title)
          .font(.headline)
        Text(header.subtitle)
          .font(.subheadline)
      }
      NavigationLink(destination: StrategyListView(phase: phase, strategies: strategies)) {
        Text(phase.rawValue)
          .font(.title2)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct ContentView: View {
  @State private var selection = 0
  private let phases = Phase.allCases
  private let data = StrategyData.load()
  private let headers = HeaderData.load()
  private let currentLayer = "Strategies"

  var body: some View {
    NavigationStack {
      TabView(selection: $selection) {
        ForEach(0 ..< (phases.count + 1), id: \.self) { index in
          let phase = phases[index % phases.count]
          let header = headers[currentLayer]
          PhasePageView(phase: phase, header: header, strategies: data[phase] ?? [])
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
}

#Preview {
  ContentView()
}
