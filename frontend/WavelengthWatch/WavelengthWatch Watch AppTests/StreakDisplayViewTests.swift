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

  @Test("view shows improving trend when current exceeds longest")
  func view_showsImprovingTrendWhenCurrentExceedsLongest() {
    let view = StreakDisplayView(
      currentStreak: 15,
      longestStreak: 12
    )

    #expect(view.trendIndicator == .improving)
  }

  @Test("view shows stable trend when current equals longest")
  func view_showsStableTrendWhenCurrentEqualsLongest() {
    let view = StreakDisplayView(
      currentStreak: 12,
      longestStreak: 12
    )

    #expect(view.trendIndicator == .stable)
  }

  @Test("view shows declining trend when current is less than longest")
  func view_showsDecliningTrendWhenCurrentIsLessThanLongest() {
    let view = StreakDisplayView(
      currentStreak: 5,
      longestStreak: 12
    )

    #expect(view.trendIndicator == .declining)
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

  @Test("view handles zero longest streak")
  func view_handlesZeroLongestStreak() {
    let view = StreakDisplayView(
      currentStreak: 5,
      longestStreak: 0
    )

    #expect(view.currentStreak == 5)
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

  @Test("view uses singular 'day' for streak of 1")
  func view_usesSingularDayForStreakOfOne() {
    let view = StreakDisplayView(
      currentStreak: 1,
      longestStreak: 5
    )

    let text = view.currentStreakText
    #expect(text.contains("Day"))
    #expect(!text.contains("Days"))
  }

  @Test("view uses plural 'days' for streak greater than 1")
  func view_usesPluralDaysForStreakGreaterThanOne() {
    let view = StreakDisplayView(
      currentStreak: 5,
      longestStreak: 12
    )

    let text = view.currentStreakText
    #expect(text.contains("Days"))
  }

  @Test("view formats longest streak subtitle correctly")
  func view_formatsLongestStreakSubtitleCorrectly() {
    let view = StreakDisplayView(
      currentStreak: 5,
      longestStreak: 12
    )

    let text = view.longestStreakText
    #expect(text.contains("Longest"))
    #expect(text.contains("12"))
  }

  // MARK: - Trend Arrow Tests

  @Test("view returns up arrow for improving trend")
  func view_returnsUpArrowForImprovingTrend() {
    let view = StreakDisplayView(
      currentStreak: 15,
      longestStreak: 12
    )

    #expect(view.trendArrow == "↑")
  }

  @Test("view returns right arrow for stable trend")
  func view_returnsRightArrowForStableTrend() {
    let view = StreakDisplayView(
      currentStreak: 12,
      longestStreak: 12
    )

    #expect(view.trendArrow == "→")
  }

  @Test("view returns down arrow for declining trend")
  func view_returnsDownArrowForDecliningTrend() {
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
    #expect(view.trendIndicator == .declining)
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
