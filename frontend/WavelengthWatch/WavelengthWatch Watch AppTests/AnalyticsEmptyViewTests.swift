import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

/// Stored-property tests for `AnalyticsEmptyView`. The icon/title/message and
/// prominence are the inputs that drive the rendered layout; the layout itself
/// is visual and covered by previews.
struct AnalyticsEmptyViewTests {
  @Test func storesIconTitleAndMessage() {
    let view = AnalyticsEmptyView(
      systemImage: "tray",
      title: "No entries yet",
      message: "Nothing here yet."
    )

    #expect(view.systemImage == "tray")
    #expect(view.title == "No entries yet")
    #expect(view.message == "Nothing here yet.")
  }

  @Test func messageDefaultsToNil() {
    let view = AnalyticsEmptyView(systemImage: "tray", title: "Empty")

    #expect(view.message == nil)
  }

  @Test func prominenceDefaultsToCompact() {
    let view = AnalyticsEmptyView(systemImage: "tray", title: "Empty")

    #expect(view.prominence == .compact)
  }

  @Test func prominenceIsPreserved() {
    let view = AnalyticsEmptyView(
      systemImage: "chart.bar",
      title: "No Data Yet",
      prominence: .prominent
    )

    #expect(view.prominence == .prominent)
  }
}
