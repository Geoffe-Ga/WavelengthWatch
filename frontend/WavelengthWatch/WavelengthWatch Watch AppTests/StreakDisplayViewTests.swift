import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("StreakDisplayView Tests")
struct StreakDisplayViewTests {
  // MARK: - Basic Display Tests

  @Test("view displays current streak")
  func view_displaysCurrentStreak() {
    let view = StreakDisplayView(
      currentStreak: 5,
      longestStreak: 12
    )

    #expect(view.currentStreak == 5)
  }

  @Test("view displays longest streak")
  func view_displaysLongestStreak() {
    let view = StreakDisplayView(
      currentStreak: 5,
      longestStreak: 12
    )

    #expect(view.longestStreak == 12)
  }

  @Test("view displays consistency score when provided")
  func view_displaysConsistencyScore() {
    let view = StreakDisplayView(
      currentStreak: 5,
      longestStreak: 12,
      consistencyScore: 83.5
    )

    #expect(view.consistencyScore == 83.5)
  }

  @Test("view handles nil consistency score")
  func view_handlesNilConsistencyScore() {
    let view = StreakDisplayView(
      currentStreak: 5,
      longestStreak: 12,
      consistencyScore: nil
    )

    #expect(view.consistencyScore == nil)
  }

  // MARK: - Trend Indicator Tests

  // NOTE: Test for currentStreak > longestStreak removed because this now triggers
  // a precondition failure (cannot be tested). The component enforces that
  // currentStreak <= longestStreak. When a record is broken, the caller must
  // update longestStreak to match currentStreak before creating the view.

  @Test("trend indicators use neutral, supportive language")
  func trendIndicators_useNeutralSupportiveLanguage() {
    let restingView = StreakDisplayView(
      currentStreak: 5,
      longestStreak: 12
    )

    // Verify resting state uses neutral color (not red/orange evaluative colors)
    let color = restingView.trendColor
    #expect(color != .red)
    #expect(color != .orange)
  }

  @Test("view shows stable trend when current equals longest")
  func view_showsStableTrendWhenCurrentEqualsLongest() {
    let view = StreakDisplayView(
      currentStreak: 12,
      longestStreak: 12
    )

    #expect(view.trendIndicator == .stable)
  }

  @Test("view shows resting trend when current is less than longest")
  func view_showsRestingTrendWhenCurrentIsLessThanLongest() {
    let view = StreakDisplayView(
      currentStreak: 5,
      longestStreak: 12
    )

    #expect(view.trendIndicator == .resting)
  }

  @Test("view shows stable trend when both streaks are zero")
  func view_showsStableTrendWhenBothStreaksAreZero() {
    let view = StreakDisplayView(
      currentStreak: 0,
      longestStreak: 0
    )

    #expect(view.trendIndicator == .stable)
  }

  // MARK: - Edge Cases

  @Test("view handles zero current streak")
  func view_handlesZeroCurrentStreak() {
    let view = StreakDisplayView(
      currentStreak: 0,
      longestStreak: 12
    )

    #expect(view.currentStreak == 0)
    #expect(view.longestStreak == 12)
  }

  // NOTE: Test for currentStreak > longestStreak removed because this violates
  // the precondition that currentStreak <= longestStreak. This edge case is now
  // semantically invalid and properly caught by the precondition.
  @Test("view handles zero longest streak")
  func view_handlesZeroLongestStreak() {
    let view = StreakDisplayView(
      currentStreak: 0,
      longestStreak: 0
    )

    #expect(view.currentStreak == 0)
    #expect(view.longestStreak == 0)
  }

  @Test("view handles single day streak")
  func view_handlesSingleDayStreak() {
    let view = StreakDisplayView(
      currentStreak: 1,
      longestStreak: 1
    )

    #expect(view.currentStreak == 1)
    #expect(view.longestStreak == 1)
    #expect(view.trendIndicator == .stable)
  }

  @Test("view handles large streak numbers")
  func view_handlesLargeStreakNumbers() {
    let view = StreakDisplayView(
      currentStreak: 365,
      longestStreak: 400
    )

    #expect(view.currentStreak == 365)
    #expect(view.longestStreak == 400)
  }

  // MARK: - Consistency Score Tests

  @Test("view handles zero consistency score")
  func view_handlesZeroConsistencyScore() {
    let view = StreakDisplayView(
      currentStreak: 0,
      longestStreak: 5,
      consistencyScore: 0.0
    )

    #expect(view.consistencyScore == 0.0)
  }

  @Test("view handles perfect consistency score")
  func view_handlesPerfectConsistencyScore() {
    let view = StreakDisplayView(
      currentStreak: 30,
      longestStreak: 30,
      consistencyScore: 100.0
    )

    #expect(view.consistencyScore == 100.0)
  }

  @Test("view handles decimal consistency score")
  func view_handlesDecimalConsistencyScore() {
    let view = StreakDisplayView(
      currentStreak: 25,
      longestStreak: 30,
      consistencyScore: 83.33
    )

    #expect(view.consistencyScore == 83.33)
  }

  // MARK: - Text Formatting Tests

  @Test("view uses neutral activity language without gamification")
  func view_usesNeutralActivityLanguage() {
    let view = StreakDisplayView(
      currentStreak: 1,
      longestStreak: 5
    )

    let text = view.currentStreakText
    // Should use neutral "Recent Activity" language, not "Streak"
    #expect(!text.contains("Streak"))
    #expect(text.contains("Recent Activity"))
  }

  @Test("view shows activity count without pressure language")
  func view_showsActivityCountWithoutPressure() {
    let view = StreakDisplayView(
      currentStreak: 5,
      longestStreak: 12
    )

    let text = view.currentStreakText
    // Should show count without gamification
    #expect(!text.contains("Streak"))
    #expect(text.contains("Recent Activity"))
  }

  @Test("view formats historical context without longest language")
  func view_formatsHistoricalContextWithoutLongest() {
    let view = StreakDisplayView(
      currentStreak: 5,
      longestStreak: 12
    )

    let text = view.longestStreakText
    // Should avoid "Longest" competitive framing
    #expect(!text.contains("Longest"))
    // Can show historical note without pressure (e.g., "Previous high")
    #expect(text.contains("12"))
    #expect(text.contains("Previous high"))
  }

  // MARK: - Trend Arrow Tests

  // NOTE: Test for up arrow (↑) removed because .improving trend no longer exists.
  // Component now only supports .stable (→) and .resting (↓) trends.

  @Test("view returns right arrow for stable trend")
  func view_returnsRightArrowForStableTrend() {
    let view = StreakDisplayView(
      currentStreak: 12,
      longestStreak: 12
    )

    #expect(view.trendArrow == "→")
  }

  @Test("view returns down arrow for resting trend")
  func view_returnsDownArrowForRestingTrend() {
    let view = StreakDisplayView(
      currentStreak: 5,
      longestStreak: 12
    )

    #expect(view.trendArrow == "↓")
  }

  // MARK: - Integration Tests

  @Test("view shows all components together")
  func view_showsAllComponentsTogether() {
    let view = StreakDisplayView(
      currentStreak: 25,
      longestStreak: 30,
      consistencyScore: 83.33
    )

    #expect(view.currentStreak == 25)
    #expect(view.longestStreak == 30)
    #expect(view.consistencyScore == 83.33)
    #expect(view.trendIndicator == .resting)
    #expect(view.trendArrow == "↓")
  }

  @Test("view works with minimal data")
  func view_worksWithMinimalData() {
    let view = StreakDisplayView(
      currentStreak: 0,
      longestStreak: 0
    )

    #expect(view.currentStreak == 0)
    #expect(view.longestStreak == 0)
    #expect(view.consistencyScore == nil)
    #expect(view.trendIndicator == .stable)
  }
}
