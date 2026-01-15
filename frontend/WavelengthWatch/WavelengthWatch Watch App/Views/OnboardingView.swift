import SwiftUI

/// Onboarding view shown on first launch.
///
/// Educates users about storage modes and privacy implications,
/// allowing them to choose between local-only and cloud-synced storage.
///
/// ## Design Principles
/// - Privacy-first: Default to local-only mode
/// - Clear explanations: Use simple language to explain trade-offs
/// - User control: Make it easy to change later in settings
/// - Accessible: Support VoiceOver and Dynamic Type
struct OnboardingView: View {
  @ObservedObject var viewModel: SyncSettingsViewModel
  @Binding var isPresented: Bool

  @State private var selectedMode: StorageMode = .localOnly

  enum StorageMode {
    case localOnly
    case cloudSynced

    var title: String {
      switch self {
      case .localOnly: "Privacy First"
      case .cloudSynced: "Cloud Backup"
      }
    }

    var icon: String {
      switch self {
      case .localOnly: "lock.shield"
      case .cloudSynced: "icloud"
      }
    }

    var description: String {
      switch self {
      case .localOnly:
        "Your journal stays on this watch. Complete privacy, no data transmission."
      case .cloudSynced:
        "Journal backed up to cloud for safe keeping and future device transfers."
      }
    }
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text("Welcome to WavelengthWatch")
          .font(.headline)
          .multilineTextAlignment(.center)

        Text("How would you like to store your journal?")
          .font(.caption)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)

        VStack(spacing: 12) {
          storageOption(.localOnly)
          storageOption(.cloudSynced)
        }

        Button {
          completeOnboarding()
        } label: {
          Text("Continue")
            .font(.headline)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityLabel("Continue with selected storage mode")

        Text("You can change this anytime in Settings")
          .font(.caption2)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }
      .padding()
    }
  }

  @ViewBuilder
  private func storageOption(_ mode: StorageMode) -> some View {
    Button {
      selectedMode = mode
    } label: {
      HStack(spacing: 12) {
        Image(systemName: mode.icon)
          .font(.title2)
          .foregroundColor(selectedMode == mode ? .blue : .secondary)
          .frame(width: 30)

        VStack(alignment: .leading, spacing: 4) {
          Text(mode.title)
            .font(.headline)
            .foregroundColor(.primary)

          Text(mode.description)
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
        }

        Spacer()

        if selectedMode == mode {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.blue)
        } else {
          Image(systemName: "circle")
            .foregroundColor(.secondary)
        }
      }
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(selectedMode == mode ? Color.blue.opacity(0.15) : Color.clear)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(selectedMode == mode ? Color.blue : Color.secondary.opacity(0.3), lineWidth: 1)
          )
      )
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(mode.title): \(mode.description)")
    .accessibilityAddTraits(selectedMode == mode ? [.isSelected] : [])
  }

  private func completeOnboarding() {
    viewModel.cloudSyncEnabled = (selectedMode == .cloudSynced)
    viewModel.completeOnboarding()
    isPresented = false
  }
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
  static var previews: some View {
    OnboardingView(
      viewModel: SyncSettingsViewModel(),
      isPresented: .constant(true)
    )
  }
}
#endif
