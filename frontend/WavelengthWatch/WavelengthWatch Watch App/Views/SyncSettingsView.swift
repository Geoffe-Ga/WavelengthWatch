import SwiftUI

/// Settings view for managing cloud sync preferences.
///
/// Displays a simple toggle for enabling/disabling cloud sync.
/// When enabled, journal entries are synced to the backend server.
/// When disabled, entries remain local-only.
///
/// ## Privacy Design
/// Cloud sync is opt-in by default. This view makes the choice explicit
/// and provides context about what data is shared.
///
/// ## Shared State
/// This view uses the shared SyncSettings instance from ContentView to ensure
/// changes take effect immediately without requiring app restart.
struct SyncSettingsView: View {
  @ObservedObject var viewModel: SyncSettingsViewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        VStack(spacing: 8) {
          Image(systemName: viewModel.cloudSyncEnabled ? "icloud.fill" : "lock.shield.fill")
            .font(.system(size: 40))
            .foregroundColor(viewModel.cloudSyncEnabled ? .blue : .green)

          Text(viewModel.cloudSyncEnabled ? "Cloud Backup" : "Privacy First")
            .font(.headline)
        }

        Toggle("Sync to Cloud", isOn: $viewModel.cloudSyncEnabled)
          .accessibilityLabel("Cloud sync toggle")

        VStack(spacing: 12) {
          if viewModel.cloudSyncEnabled {
            privacyExplanation(
              icon: "checkmark.circle.fill",
              color: .blue,
              title: "Cloud Backup Active",
              description: "Your journal entries are backed up to the cloud for safe keeping and future device transfers."
            )
            privacyExplanation(
              icon: "lock.fill",
              color: .blue,
              title: "Your Data",
              description: "Entries are associated with your device ID, not your Apple ID. Data is used for anonymized analytics aggregation."
            )
          } else {
            privacyExplanation(
              icon: "lock.shield.fill",
              color: .green,
              title: "Complete Privacy",
              description: "Your journal stays on this watch. No data transmission, complete privacy."
            )
            privacyExplanation(
              icon: "checkmark.circle.fill",
              color: .green,
              title: "Analytics Work Offline",
              description: "All insights and analytics are computed locally on your device."
            )
          }
        }

        Text("You can change this anytime")
          .font(.caption2)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)

        Spacer()
      }
      .padding()
    }
    .navigationTitle("Sync Settings")
    .navigationBarTitleDisplayMode(.inline)
  }

  @ViewBuilder
  private func privacyExplanation(icon: String, color: Color, title: String, description: String) -> some View {
    HStack(alignment: .top, spacing: 8) {
      Image(systemName: icon)
        .foregroundColor(color)
        .font(.caption)
        .frame(width: 16)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.caption)
          .fontWeight(.semibold)

        Text(description)
          .font(.caption2)
          .foregroundColor(.secondary)
      }
    }
  }
}

#if DEBUG
struct SyncSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      SyncSettingsView(viewModel: SyncSettingsViewModel())
    }
  }
}
#endif
