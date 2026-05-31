import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

/// Stored-property tests for `AnalyticsErrorView`. The retry button's
/// presence is driven entirely by whether a `retry` closure was supplied, so
/// that branch is the meaningful unit-testable contract; the rendered layout
/// is visual and covered by previews.
struct AnalyticsErrorViewTests {
  @Test func storesMessage() {
    let view = AnalyticsErrorView(message: "Couldn't load insights.")

    #expect(view.message == "Couldn't load insights.")
  }

  @Test func retryDefaultsToNil() {
    let view = AnalyticsErrorView(message: "Boom")

    #expect(view.retry == nil)
  }

  @Test func retryIsPreservedWhenProvided() {
    let view = AnalyticsErrorView(message: "Boom", retry: {})

    #expect(view.retry != nil)
  }
}
