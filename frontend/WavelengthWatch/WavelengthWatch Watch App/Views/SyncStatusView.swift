import SwiftUI

/// Displays queue status, network connectivity, and manual sync controls.
///
/// Shown from the main menu whenever users want to inspect or force a
/// retry of the offline journal queue. Observes `JournalQueue`,
/// `JournalSyncService`, and `NetworkMonitor` so all rendered state stays
/// in sync with the underlying services.
struct SyncStatusView: View {
  @ObservedObject var queue: JournalQueue
  @ObservedObject var syncService: JournalSyncService
  @ObservedObject var networkMonitor: NetworkMonitor
  @State private var manualSyncError: String?

  var body: some View {
    List {
      Section("Network") {
        HStack {
          Image(systemName: networkMonitor.isConnected ? "wifi" : "wifi.slash")
            .foregroundColor(networkMonitor.isConnected ? .green : .red)
          Text(networkMonitor.isConnected ? "Online" : "Offline")
          Spacer()
          Circle()
            .fill(networkMonitor.isConnected ? Color.green : Color.red)
            .frame(width: 8, height: 8)
        }
      }

      Section("Queue") {
        HStack {
          Text("Pending Entries")
          Spacer()
          Text("\(queue.pendingCount)")
            .foregroundColor(.secondary)
            .monospacedDigit()
        }

        if case let .syncing(progress) = syncService.syncStatus {
          HStack(spacing: 8) {
            ProgressView(value: progress)
              .progressViewStyle(.linear)
            Text("\(Int(progress * 100))%")
              .font(.caption2)
              .foregroundColor(.secondary)
              .monospacedDigit()
          }
        } else if syncService.isSyncing {
          HStack {
            ProgressView()
            Text("Syncing…")
          }
        }

        if queue.pendingCount > 0 {
          Button("Sync Now") {
            manualSyncError = nil
            Task {
              do {
                try await syncService.sync()
              } catch {
                manualSyncError = error.localizedDescription
              }
            }
          }
          .disabled(!networkMonitor.isConnected || syncService.isSyncing)
        }
      }

      if let manualSyncError {
        Section("Last Error") {
          Text(manualSyncError)
            .font(.caption)
            .foregroundColor(.red)
        }
      } else if case let .success(count) = syncService.syncStatus, count > 0 {
        Section("Last Sync") {
          HStack {
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(.green)
            Text("Synced \(count) entr\(count == 1 ? "y" : "ies")")
              .font(.caption)
          }
        }
      }
    }
    .navigationTitle("Sync Status")
    .navigationBarTitleDisplayMode(.inline)
  }
}
