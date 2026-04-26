import Foundation

/// Locale-aware formatter for 0-23 hour-of-day values.
///
/// Both `TemporalPatternsView` row labels and
/// `JournalEntryDrilldownFilter` drill-down titles route through this
/// helper so the user sees identical strings on the source surface
/// and the destination screen.
///
/// The "h a" template defers AM/PM strings (and ordering) to the
/// supplied locale; en-US renders "9 AM" / "1 PM", while a 12-hour
/// locale that uses different period markers (e.g. "오전 9시" in ko-KR)
/// gets the appropriate localization.
enum HourFormatter {
  static func display(_ hour: Int, locale: Locale = .current) -> String {
    var components = DateComponents()
    components.hour = hour
    let calendar = Calendar(identifier: .gregorian)
    guard let date = calendar.date(from: components) else {
      return "\(hour)"
    }

    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.setLocalizedDateFormatFromTemplate("h a")
    return formatter.string(from: date)
  }
}
