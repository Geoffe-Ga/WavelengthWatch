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

  /// Accent for the active mode: blue when cloud sync is on, green when
  /// the journal stays local-only.
  private var accent: Color {
    viewModel.cloudSyncEnabled ? WLColorTokens.syncAccent : WLColorTokens.privacyAccent
  }

  var body: some View {
    Form {
      Section {
        VStack(spacing: 8) {
          Image(systemName: viewModel.cloudSyncEnabled ? "icloud.fill" : "lock.shield.fill")
            .font(.system(size: 40))
            .foregroundStyle(accent)
            .accessibilityHidden(true)

          Text(viewModel.cloudSyncEnabled ? "Cloud Backup" : "Privacy First")
            .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
      }

      Section {
        Toggle("Sync to Cloud", isOn: $viewModel.cloudSyncEnabled)
          .accessibilityLabel("Cloud sync toggle")
      } footer: {
        Text("You can change this anytime")
          .font(WLTypographyTokens.tag)
          .foregroundStyle(.secondary)
      }

      Section {
        if viewModel.cloudSyncEnabled {
          privacyExplanation(
            icon: "checkmark.circle.fill",
            color: WLColorTokens.syncAccent,
            title: "Cloud Backup Active",
            description: "Your journal entries are backed up to the cloud for safe keeping and future device transfers."
          )
          privacyExplanation(
            icon: "lock.fill",
            color: WLColorTokens.syncAccent,
            title: "Your Data",
            description: "Entries are associated with your device ID, not your Apple ID. Data is used for anonymized analytics aggregation."
          )
        } else {
          privacyExplanation(
            icon: "lock.shield.fill",
            color: WLColorTokens.privacyAccent,
            title: "Complete Privacy",
            description: "Your journal stays on this watch. No data transmission, complete privacy."
          )
          privacyExplanation(
            icon: "checkmark.circle.fill",
            color: WLColorTokens.privacyAccent,
            title: "Analytics Work Offline",
            description: "All insights and analytics are computed locally on your device."
          )
        }
      }
    }
    .navigationTitle("Sync Settings")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func privacyExplanation(icon: String, color: Color, title: String, description: String) -> some View {
    HStack(alignment: .top, spacing: 8) {
      Image(systemName: icon)
        .foregroundStyle(color)
        .font(.caption)
        .frame(width: 16)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.caption)
          .fontWeight(.semibold)

        Text(description)
          .font(.caption2)
          .foregroundStyle(.secondary)
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
