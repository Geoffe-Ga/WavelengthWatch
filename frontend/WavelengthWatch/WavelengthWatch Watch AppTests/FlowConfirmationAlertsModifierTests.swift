import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

/// Coverage for `FlowConfirmationAlertsModifier.presenter(for:coordinator:)`
/// — the per-step binding whose write side maps a system dismissal of a
/// confirmation alert onto `FlowCoordinator.cancel()` (filed as #327).
@MainActor
struct FlowConfirmationAlertsModifierTests {
  private func makeCoordinator() async -> (FlowCoordinator, CatalogResponseModel) {
    let catalog = CatalogTestHelper.createTestCatalog()
    let repository = CatalogRepositoryMock(cached: catalog, result: .success(catalog))
    let viewModel = ContentViewModel(
      catalogRepository: repository,
      journalRepository: InMemoryJournalRepository(),
      journalClient: JournalClientMock()
    )
    await viewModel.loadCatalog()
    return (FlowCoordinator(contentViewModel: viewModel), catalog)
  }

  // MARK: - Getter

  @Test("getter is true only while the coordinator is in the matching step")
  func getter_matchesStep() async {
    let (coordinator, catalog) = await makeCoordinator()
    let binding = FlowConfirmationAlertsModifier.presenter(
      for: .confirmingPrimary,
      coordinator: coordinator
    )

    #expect(binding.wrappedValue == false)

    coordinator.capturePrimary(catalog.layers[1].phases[0].medicinal[0])
    #expect(binding.wrappedValue == true)

    coordinator.promptForStrategy()
    #expect(binding.wrappedValue == false)
  }

  // MARK: - Setter — implicit cancel

  @Test("writing false while in the step cancels the flow")
  func setterFalse_inStep_cancelsFlow() async {
    let (coordinator, catalog) = await makeCoordinator()
    coordinator.capturePrimary(catalog.layers[1].phases[0].medicinal[0])
    let binding = FlowConfirmationAlertsModifier.presenter(
      for: .confirmingPrimary,
      coordinator: coordinator
    )

    binding.wrappedValue = false

    #expect(coordinator.currentStep == .idle)
    #expect(coordinator.selections.primary == nil)
  }

  // MARK: - Setter — step guard

  @Test("writing false for a step the coordinator is not in does not cancel")
  func setterFalse_otherStep_doesNotCancel() async {
    let (coordinator, catalog) = await makeCoordinator()
    let primary = catalog.layers[1].phases[0].medicinal[0]
    coordinator.capturePrimary(primary)
    // Binding for a step the coordinator is NOT currently in.
    let binding = FlowConfirmationAlertsModifier.presenter(
      for: .confirmingStrategy,
      coordinator: coordinator
    )

    binding.wrappedValue = false

    #expect(coordinator.currentStep == .confirmingPrimary)
    #expect(coordinator.selections.primary == primary)
  }
}
