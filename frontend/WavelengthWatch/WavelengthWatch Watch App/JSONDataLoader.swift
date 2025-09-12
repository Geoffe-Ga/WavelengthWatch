//
//  JSONDataLoader.swift
//  WavelengthWatch Watch App
//
//  JSON data loading utilities for WavelengthWatch
//

import Foundation

enum JSONDataLoader {
  enum LoadingError: Error {
    case fileNotFound(String)
    case decodingFailed(String, Error)
  }

  /// Load and decode JSON data from the app bundle
  static func load<T: Decodable>(_ type: T.Type, from filename: String) throws -> T {
    guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
      throw LoadingError.fileNotFound("Could not find \(filename).json in app bundle")
    }

    let data = try Data(contentsOf: url)

    do {
      let decoder = JSONDecoder()
      return try decoder.decode(type, from: data)
    } catch {
      throw LoadingError.decodingFailed("Failed to decode \(filename).json", error)
    }
  }

  /// Load strategies data with proper phase mapping
  static func loadStrategies() -> [Phase: [Strategy]] {
    do {
      let decoded = try load([String: [Strategy]].self, from: "a-w-strategies")
      var result: [Phase: [Strategy]] = [:]
      for phase in Phase.allCases {
        result[phase] = decoded[phase.rawValue] ?? []
      }
      return result
    } catch {
      print("⚠️ Failed to load strategies from JSON: \(error)")
      // Return empty data as fallback
      return [:]
    }
  }

  /// Load headers data
  static func loadHeaders() -> [String: LayerHeader] {
    do {
      return try load([String: LayerHeader].self, from: "a-w-headers")
    } catch {
      print("⚠️ Failed to load headers from JSON: \(error)")
      // Return empty data as fallback
      return [:]
    }
  }

  /// Load curriculum data with proper phase mapping
  static func loadCurriculum() -> [String: [Phase: CurriculumEntry]] {
    do {
      let decoded = try load([String: [String: CurriculumEntry]].self, from: "a-w-curriculum")
      var result: [String: [Phase: CurriculumEntry]] = [:]
      for (layer, phases) in decoded {
        var phaseMap: [Phase: CurriculumEntry] = [:]
        for (phaseName, entry) in phases {
          if let phase = Phase(rawValue: phaseName) {
            phaseMap[phase] = entry
          }
        }
        result[layer] = phaseMap
      }
      return result
    } catch {
      print("⚠️ Failed to load curriculum from JSON: \(error)")
      // Return empty data as fallback
      return [:]
    }
  }
}
