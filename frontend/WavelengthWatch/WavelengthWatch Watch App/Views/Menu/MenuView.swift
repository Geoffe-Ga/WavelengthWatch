import SwiftUI

struct MenuView: View {
  let journalClient: JournalClientProtocol
  @ObservedObject var syncSettingsViewModel: SyncSettingsViewModel
  @Binding var isPresented: Bool
  @EnvironmentObject private var viewModel: ContentViewModel
  @EnvironmentObject private var flowCoordinator: FlowCoordinator
  @State private var showingStartPrompt = false

  var body: some View {
    List {
      // Log Emotion uses sheet presentation for modal flow
      // (other menu items use NavigationLink for settings navigation)
      Button {
        // Guard: Ensure catalog hasn't been cleared between button tap and sheet presentation
        if viewModel.layers.count > 0 {
          showingStartPrompt = true
        }
      } label: {
        Label("Log Emotion", systemImage: "heart.text.square")
      }
      .disabled(viewModel.layers.count == 0)
      .accessibilityLabel("Log your current emotion")
      .accessibilityHint("Opens emotion logging flow")

      NavigationLink(destination: ScheduleSettingsView()) {
        Label("Schedules", systemImage: "clock")
      }

      NavigationLink(destination: AnalyticsView(
        journalRepository: viewModel.journalRepository,
        catalogRepository: viewModel.catalogRepository
      )) {
        Label("Analytics", systemImage: "chart.bar")
      }

      NavigationLink(destination: SyncSettingsView(viewModel: syncSettingsViewModel)) {
        Label("Sync Settings", systemImage: "arrow.triangle.2.circlepath")
      }

      NavigationLink(destination: ConceptExplainerView()) {
        Label("About Archetypal Wavelength", systemImage: "book")
      }
    }
    .navigationTitle("Menu")
    .navigationBarTitleDisplayMode(.inline)
    .alert("Select your primary emotion", isPresented: $showingStartPrompt) {
      Button("Continue") {
        flowCoordinator.startPrimarySelection()
        // Dismiss menu sheet when flow starts (fixes #156)
        isPresented = false
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Navigate to any emotion and tap to log it.")
    }
  }
}
