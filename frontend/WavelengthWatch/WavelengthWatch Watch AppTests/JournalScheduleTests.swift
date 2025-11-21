import Foundation
import Testing

@testable import WavelengthWatch_Watch_App

@Suite("JournalSchedule Tests")
struct JournalScheduleTests {
  @Test func encodesAndDecodesSchedule() throws {
    var time = DateComponents()
    time.hour = 8
    time.minute = 0

    let schedule = JournalSchedule(
      id: UUID(),
      time: time,
      enabled: true,
      repeatDays: [1, 2, 3, 4, 5]
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(schedule)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(JournalSchedule.self, from: data)

    #expect(decoded.id == schedule.id)
    #expect(decoded.time.hour == 8)
    #expect(decoded.time.minute == 0)
    #expect(decoded.enabled == true)
    #expect(decoded.repeatDays == [1, 2, 3, 4, 5])
  }

  @Test func validatesRepeatDays() {
    var time = DateComponents()
    time.hour = 8
    time.minute = 0

    let validSchedule = JournalSchedule(time: time, repeatDays: [0, 6])
    #expect(validSchedule.isValid)

    let invalidSchedule = JournalSchedule(time: time, repeatDays: [-1, 7])
    #expect(!invalidSchedule.isValid)
  }

  @Test func defaultsToAllDaysEnabled() {
    var time = DateComponents()
    time.hour = 8
    time.minute = 0

    let schedule = JournalSchedule(time: time)
    #expect(schedule.enabled == true)
    #expect(schedule.repeatDays == [0, 1, 2, 3, 4, 5, 6])
  }
}
