import Testing
@testable import WavelengthWatch_Watch_App

/// Tests for the journal log-confirmation migration (#406, fixes B2).
///
/// Two layers under test: the coordinator's intent→presentation mapping
/// for `.logConfirmation`, and `LogConfirmationHandler`'s branching, which
/// must reproduce exactly what the three leaf cards' former
/// `handleLogAction` did — flow-selection steps capture into
/// `FlowCoordinator`; every other step logs directly via `journal`.
@MainActor
struct LogConfirmationTests {
  private func setup() async -> (ContentViewModel, FlowCoordinator, JournalClientMock, CatalogResponseModel) {
    let catalog = CatalogTestHelper.createTestCatalog()
    let repository = CatalogRepositoryMock(cached: catalog, result: .success(catalog))
    let journalClient = JournalClientMock()
    let viewModel = ContentViewModel(
      catalogRepository: repository,
      journalRepository: InMemoryJournalRepository(),
      journalClient: journalClient
    )
    await viewModel.loadCatalog()
    let coordinator = FlowCoordinator(contentViewModel: viewModel)
    return (viewModel, coordinator, journalClient, catalog)
  }

  // MARK: - Coordinator mapping

  @Test("request(.logConfirmation) activates the confirmation with its payload")
  func request_logConfirmation_activates() {
    let coordinator = PresentationCoordinator()
    let request = LogConfirmationRequest(
      alertTitle: "Log Strategy",
      message: "Would you like to log \"Deep Breathing\"?",
      action: .strategy(
        strategy: CatalogStrategyModel(id: 1, strategy: "Deep Breathing", color: "Blue"),
        curriculumID: 10
      )
    )

    coordinator.request(.logConfirmation(request))
    #expect(coordinator.active == .logConfirmation(request))

    coordinator.dismiss()
    #expect(coordinator.active == .idle)
  }

  // MARK: - Handler: curriculum

  @Test("curriculum action from idle quick-logs immediately without entering the flow")
  func handler_curriculum_fromIdle_quickLogsImmediately() async {
    let (viewModel, flow, journalClient, catalog) = await setup()
    let entry = catalog.layers[1].phases[0].medicinal[0]
    let handler = LogConfirmationHandler(flowCoordinator: flow, viewModel: viewModel)

    await handler.perform(.curriculum(entry: entry))

    // Quick-log (#427): one confirm persists exactly one row right now,
    // and must NOT auto-start the guided flow or change the layer filter.
    #expect(journalClient.submissions.count == 1)
    #expect(flow.currentStep == .idle)
    #expect(flow.selections.primary == nil)
    #expect(viewModel.layerFilterMode == .all)
  }

  @Test("curriculum action while selectingPrimary captures primary")
  func handler_curriculum_selectingPrimary_captures() async {
    let (viewModel, flow, _, catalog) = await setup()
    let entry = catalog.layers[1].phases[0].medicinal[0]
    flow.startPrimarySelection()
    let handler = LogConfirmationHandler(flowCoordinator: flow, viewModel: viewModel)

    await handler.perform(.curriculum(entry: entry))

    #expect(flow.currentStep == .confirmingPrimary)
    #expect(flow.selections.primary == entry)
  }

  @Test("curriculum action while selectingSecondary captures secondary")
  func handler_curriculum_selectingSecondary_captures() async {
    let (viewModel, flow, _, catalog) = await setup()
    let entry = catalog.layers[2].phases[0].medicinal[0]
    flow.promptForSecondary()
    let handler = LogConfirmationHandler(flowCoordinator: flow, viewModel: viewModel)

    await handler.perform(.curriculum(entry: entry))

    #expect(flow.currentStep == .confirmingSecondary)
    #expect(flow.selections.secondary == entry)
  }

  @Test("curriculum action in a non-selecting step logs directly")
  func handler_curriculum_default_logs() async {
    let (viewModel, flow, journalClient, catalog) = await setup()
    let entry = catalog.layers[1].phases[0].medicinal[0]
    flow.showReview() // a "default"-branch step

    let handler = LogConfirmationHandler(flowCoordinator: flow, viewModel: viewModel)
    await handler.perform(.curriculum(entry: entry))

    #expect(journalClient.submissions.count == 1)
  }

  // MARK: - Handler: strategy

  @Test("strategy action while selectingStrategy captures the strategy")
  func handler_strategy_selectingStrategy_captures() async {
    let (viewModel, flow, journalClient, catalog) = await setup()
    let strategy = catalog.layers[0].phases[0].strategies[0]
    flow.promptForStrategy()
    let handler = LogConfirmationHandler(flowCoordinator: flow, viewModel: viewModel)

    await handler.perform(.strategy(strategy: strategy, curriculumID: nil))

    #expect(flow.currentStep == .confirmingStrategy)
    #expect(flow.selections.strategy == strategy)
    #expect(journalClient.submissions.isEmpty)
  }

  @Test("strategy action with a curriculum id logs directly when not selecting")
  func handler_strategy_withCurriculumID_logs() async {
    let (viewModel, flow, journalClient, catalog) = await setup()
    let strategy = catalog.layers[0].phases[0].strategies[0]
    let curriculumID = catalog.layers[1].phases[0].medicinal[0].id
    let handler = LogConfirmationHandler(flowCoordinator: flow, viewModel: viewModel)

    await handler.perform(.strategy(strategy: strategy, curriculumID: curriculumID))

    #expect(journalClient.submissions.count == 1)
  }

  @Test("strategy action without a curriculum id and not selecting is a no-op")
  func handler_strategy_noCurriculumID_isNoOp() async {
    let (viewModel, flow, journalClient, catalog) = await setup()
    let strategy = catalog.layers[0].phases[0].strategies[0]
    let handler = LogConfirmationHandler(flowCoordinator: flow, viewModel: viewModel)

    await handler.perform(.strategy(strategy: strategy, curriculumID: nil))

    #expect(journalClient.submissions.isEmpty)
    #expect(flow.currentStep == .idle)
  }
}
