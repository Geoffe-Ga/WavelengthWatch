import SwiftUI

/// Compact row showing one journal entry inside `JournalEntryListView`:
/// timestamp, optional emotion expression, optional strategy name.
struct JournalEntryRowView: View {
  let entry: LocalJournalEntry
  let expressionById: [Int: String]
  let strategyNameById: [Int: String]

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(entry.createdAt, format: .dateTime.month().day().hour().minute())
        .font(.caption)
        .fontWeight(.semibold)

      if let expression {
        Text(expression)
          .font(.caption2)
          .foregroundColor(.secondary)
          .lineLimit(1)
      }

      if let strategyName {
        HStack(spacing: 4) {
          Image(systemName: "leaf")
            .font(.system(size: 9))
            .foregroundColor(.secondary)
          Text(strategyName)
            .font(.system(size: 10))
            .foregroundColor(.secondary)
            .lineLimit(1)
        }
      }
    }
    .padding(.vertical, 2)
  }

  private var expression: String? {
    guard let cid = entry.curriculumID else { return nil }
    return expressionById[cid]
  }

  private var strategyName: String? {
    guard let sid = entry.strategyID else { return nil }
    return strategyNameById[sid]
  }
}

/// Placeholder shown when the drill-down filter matches no journal entries.
struct JournalEntryListEmptyStateView: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "tray")
        .font(.title)
        .foregroundColor(.secondary)
      Text("No entries yet")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

/// Placeholder shown when entry fetch fails.
struct JournalEntryListErrorStateView: View {
  let message: String

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "exclamationmark.triangle")
        .font(.title)
        .foregroundColor(.orange)
      Text(message)
        .font(.caption2)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
