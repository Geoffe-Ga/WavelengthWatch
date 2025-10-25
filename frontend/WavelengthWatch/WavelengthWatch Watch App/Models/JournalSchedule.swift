import Foundation

/// Represents a scheduled journal prompt configuration
struct JournalSchedule: Codable, Identifiable, Equatable {
  let id: UUID
  var time: DateComponents
  var enabled: Bool
  var repeatDays: Set<Int> // 0 = Sunday, 6 = Saturday

  init(
    id: UUID = UUID(),
    time: DateComponents,
    enabled: Bool = true,
    repeatDays: Set<Int> = [0, 1, 2, 3, 4, 5, 6]
  ) {
    self.id = id
    self.time = time
    self.enabled = enabled
    self.repeatDays = repeatDays
  }

  // MARK: - Validation

  /// Validates that repeatDays only contains values 0-6
  var isValid: Bool {
    repeatDays.allSatisfy { $0 >= 0 && $0 <= 6 }
  }

  // MARK: - Codable

  enum CodingKeys: String, CodingKey {
    case id
    case time
    case enabled
    case repeatDays
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(UUID.self, forKey: .id)
    self.time = try container.decode(DateComponents.self, forKey: .time)
    self.enabled = try container.decode(Bool.self, forKey: .enabled)
    let repeatDaysArray = try container.decode([Int].self, forKey: .repeatDays)
    self.repeatDays = Set(repeatDaysArray)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(time, forKey: .time)
    try container.encode(enabled, forKey: .enabled)
    try container.encode(Array(repeatDays).sorted(), forKey: .repeatDays)
  }
}
