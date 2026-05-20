import Testing
@testable import WavelengthWatch_Watch_App

/// Regression coverage for `MainContentDialogsModifier.flowReviewPresenter(for:)`
/// — the derived `Binding<Bool>` that maps a system swipe-dismiss of the
/// flow-review sheet onto `FlowCoordinator.cancel()` (filed from #336 review).
@MainActor
struct MainContentDialogsModifierTests {
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

  @Test("getter is true only while the coordinator is in .review")
  func getter_isTrueOnlyInReview() async {
    let (coordinator, _) = await makeCoordinator()
    let binding = MainContentDialogsModifier.flowReviewPresenter(for: coordinator)

    #expect(binding.wrappedValue == false)

    coordinator.startPrimarySelection()
    #expect(binding.wrappedValue == false)

    coordinator.showReview()
    #expect(binding.wrappedValue == true)
  }

  // MARK: - Setter — implicit cancel

  @Test("writing false while in .review cancels the flow")
  func setterFalse_inReview_cancelsFlow() async {
    let (coordinator, catalog) = await makeCoordinator()
    coordinator.capturePrimary(catalog.layers[1].phases[0].medicinal[0])
    coordinator.showReview()
    let binding = MainContentDialogsModifier.flowReviewPresenter(for: coordinator)

    binding.wrappedValue = false

    #expect(coordinator.currentStep == .idle)
    #expect(coordinator.selections.primary == nil)
    #expect(coordinator.contentViewModel.layerFilterMode == .all)
  }

  // MARK: - Setter — step guard

  @Test("writing false outside .review does not cancel the flow")
  func setterFalse_outsideReview_doesNotCancel() async {
    let (coordinator, catalog) = await makeCoordinator()
    let primary = catalog.layers[1].phases[0].medicinal[0]
    coordinator.capturePrimary(primary)
    let binding = MainContentDialogsModifier.flowReviewPresenter(for: coordinator)

    binding.wrappedValue = false

    #expect(coordinator.currentStep == .confirmingPrimary)
    #expect(coordinator.selections.primary == primary)
  }
}
