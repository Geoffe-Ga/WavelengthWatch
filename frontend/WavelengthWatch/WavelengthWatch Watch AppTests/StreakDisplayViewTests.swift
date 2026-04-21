import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

struct StreakDisplayViewTests {
  // MARK: - Initialization

  @Test("view stores monthly check-in count")
  func view_storesMonthlyCheckInCount() {
    let view = StreakDisplayView(monthlyCheckIns: 7)
    #expect(view.monthlyCheckIns == 7)
  }

  @Test("view accepts zero check-ins")
  func view_acceptsZeroCheckIns() {
    let view = StreakDisplayView(monthlyCheckIns: 0)
    #expect(view.monthlyCheckIns == 0)
  }

  @Test("view accepts large check-in counts")
  func view_acceptsLargeCheckInCounts() {
    let view = StreakDisplayView(monthlyCheckIns: 365)
    #expect(view.monthlyCheckIns == 365)
  }

  // MARK: - Activity Text

  @Test("activity text uses plural for zero check-ins")
  func activityText_usesPluralForZero() {
    let view = StreakDisplayView(monthlyCheckIns: 0)
    #expect(view.activityText == "0 check-ins in the last 30 days")
  }

  @Test("activity text uses singular for one check-in")
  func activityText_usesSingularForOne() {
    let view = StreakDisplayView(monthlyCheckIns: 1)
    #expect(view.activityText == "1 check-in in the last 30 days")
  }

  @Test("activity text uses plural for multiple check-ins")
  func activityText_usesPluralForMany() {
    let view = StreakDisplayView(monthlyCheckIns: 12)
    #expect(view.activityText == "12 check-ins in the last 30 days")
  }

  // MARK: - Neutral, non-gamified language

  @Test("activity text removes all streak terminology")
  func activityText_removesStreakTerminology() {
    let view = StreakDisplayView(monthlyCheckIns: 5)
    let text = view.activityText
    #expect(!text.contains("Streak"))
    #expect(!text.contains("streak"))
    #expect(!text.contains("🔥"))
    #expect(!text.contains("Longest"))
    #expect(!text.contains("Previous high"))
  }

  @Test("context text affirms natural rhythms without pressure")
  func contextText_affirmsNaturalRhythms() {
    let view = StreakDisplayView(monthlyCheckIns: 5)
    let text = view.contextText
    #expect(!text.contains("should"))
    #expect(!text.contains("goal"))
    #expect(!text.contains("streak"))
    #expect(text.lowercased().contains("natural"))
  }
}
