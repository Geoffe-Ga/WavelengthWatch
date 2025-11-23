import SwiftUI

/// Sheet content for notification-triggered emotion logging flow.
/// Reactively responds to catalog loading state changes.
struct NotificationFlowSheet: View {
  @EnvironmentObject var viewModel: ContentViewModel
  let initiatedBy: InitiatedBy
  let journalClient: JournalClientProtocol
  @Binding var isPresented: Bool

  var body: some View {
    if viewModel.layers.count > 0 {
      // Catalog loaded - show the flow
      FlowCoordinatorView(
        catalog: CatalogResponseModel(
          phaseOrder: viewModel.phaseOrder,
          layers: viewModel.layers
        ),
        initiatedBy: initiatedBy,
        journalClient: journalClient,
        isPresented: $isPresented
      )
    } else if viewModel.isLoading {
      // Catalog still loading
      VStack(spacing: 12) {
        ProgressView("Loading curriculum…")
      }
      .padding()
    } else {
      // Catalog load failed
      VStack(spacing: 12) {
        Text("Unable to load emotion catalog")
          .font(.footnote)
          .multilineTextAlignment(.center)
        Button("Dismiss") {
          isPresented = false
        }
      }
      .padding()
    }
  }
}
