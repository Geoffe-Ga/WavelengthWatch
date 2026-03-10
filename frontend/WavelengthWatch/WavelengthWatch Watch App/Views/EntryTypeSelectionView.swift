import SwiftUI

/// Entry type selection view for journal flow.
///
/// Presents two options:
/// - "Log an Emotion" (heart icon, blue background)
/// - "Honoring Rest" (moon.zzz icon, purple background)
@MainActor
struct EntryTypeSelectionView: View {
  @ObservedObject var flowViewModel: JournalFlowViewModel
  let onSelect: (EntryType) -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Text("How are you checking in?")
          .font(.title3)
          .fontWeight(.semibold)
          .multilineTextAlignment(.center)
          .padding(.top)

        // Log an Emotion option
        Button {
          onSelect(.emotion)
        } label: {
          VStack(spacing: 12) {
            Image(systemName: "heart.fill")
              .font(.system(size: 40))
              .foregroundColor(.white)

            Text("Log an Emotion")
              .font(.body)
              .fontWeight(.semibold)
              .foregroundColor(.white)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 24)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(
                LinearGradient(
                  gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.blue.opacity(0.6),
                  ]),
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .shadow(color: Color.blue.opacity(0.3), radius: 8)
          )
        }
        .buttonStyle(.plain)

        // Honoring Rest option
        Button {
          onSelect(.rest)
        } label: {
          VStack(spacing: 12) {
            Image(systemName: "moon.zzz.fill")
              .font(.system(size: 40))
              .foregroundColor(.white)

            Text("Honoring Rest")
              .font(.body)
              .fontWeight(.semibold)
              .foregroundColor(.white)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 24)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(
                LinearGradient(
                  gradient: Gradient(colors: [
                    Color.purple.opacity(0.8),
                    Color.purple.opacity(0.6),
                  ]),
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .shadow(color: Color.purple.opacity(0.3), radius: 8)
          )
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal)
    }
  }
}

// MARK: - Previews

#Preview {
  let catalog = CatalogResponseModel(
    phaseOrder: ["Rising"],
    layers: []
  )

  let viewModel = JournalFlowViewModel(catalog: catalog)

  return EntryTypeSelectionView(
    flowViewModel: viewModel,
    onSelect: { type in
      print("Selected: \(type)")
    }
  )
}
