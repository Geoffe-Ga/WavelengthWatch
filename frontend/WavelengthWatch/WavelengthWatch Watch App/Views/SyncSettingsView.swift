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
struct SyncSettingsView: View {
  @StateObject private var viewModel = SyncSettingsViewModel()
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 16) {
      Text("Sync Settings")
        .font(.headline)

      Toggle("Sync to Cloud", isOn: $viewModel.cloudSyncEnabled)

      Text("When enabled, your journal entries will sync to the cloud for backup and cross-device access.")
        .font(.caption2)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)

      Spacer()
    }
    .padding()
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#if DEBUG
struct SyncSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      SyncSettingsView()
    }
  }
}
#endif
