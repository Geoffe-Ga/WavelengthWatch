import Testing
@testable import WavelengthWatch_Watch_App

/// Regression coverage for `RootPresentationHost.flowReviewPresented(coordinator:flowCoordinator:)`
/// — the derived `Binding<Bool>` that maps a system swipe-dismiss of the
/// flow-review sheet onto `FlowCoordinator.cancel()` (originally #336;
/// relocated from `MainContentDialogsModifier` onto the presentation host
/// in #407).
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

  @Test("getter is true only while the coordinator's active presentation is .flowReview")
  func getter_isTrueOnlyInFlowReview() async {
    let (flowCoordinator, _) = await makeCoordinator()
    let presentation = PresentationCoordinator()
    let binding = RootPresentationHost.flowReviewPresented(
      coordinator: presentation,
      flowCoordinator: flowCoordinator
    )

    #expect(binding.wrappedValue == false)

    presentation.request(.menu)
    #expect(binding.wrappedValue == false)

    presentation.dismiss()
    presentation.request(.flowReview)
    #expect(binding.wrappedValue == true)
  }

  // MARK: - Setter — implicit cancel

  @Test("writing false while the flow is in .review cancels the flow and dismisses")
  func setterFalse_inReview_cancelsFlow() async {
    let (flowCoordinator, catalog) = await makeCoordinator()
    flowCoordinator.capturePrimary(catalog.layers[1].phases[0].medicinal[0])
    flowCoordinator.showReview()
    let presentation = PresentationCoordinator()
    presentation.request(.flowReview)
    let binding = RootPresentationHost.flowReviewPresented(
      coordinator: presentation,
      flowCoordinator: flowCoordinator
    )

    binding.wrappedValue = false

    #expect(presentation.active == .idle)
    #expect(flowCoordinator.currentStep == .idle)
    #expect(flowCoordinator.selections.primary == nil)
    #expect(flowCoordinator.contentViewModel.layerFilterMode == .all)
  }

  // MARK: - Setter — step guard

  @Test("writing false while the flow is not in .review dismisses but does not cancel the flow")
  func setterFalse_outsideReview_doesNotCancel() async {
    let (flowCoordinator, catalog) = await makeCoordinator()
    let primary = catalog.layers[1].phases[0].medicinal[0]
    flowCoordinator.capturePrimary(primary)
    let presentation = PresentationCoordinator()
    presentation.request(.flowReview)
    let binding = RootPresentationHost.flowReviewPresented(
      coordinator: presentation,
      flowCoordinator: flowCoordinator
    )

    binding.wrappedValue = false

    #expect(presentation.active == .idle)
    #expect(flowCoordinator.currentStep == .confirmingPrimary)
    #expect(flowCoordinator.selections.primary == primary)
  }
}
