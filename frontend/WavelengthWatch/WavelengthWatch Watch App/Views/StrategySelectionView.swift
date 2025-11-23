import SwiftUI

/// View for selecting an optional strategy from layer 0.
///
/// Shows only strategies layer, pre-scrolled to phase matching primary emotion.
/// Displays emotion context and allows continuing without strategy selection.
@MainActor
struct StrategySelectionView: View {
  let catalog: CatalogResponseModel
  @ObservedObject var flowViewModel: JournalFlowViewModel

  @State private var selectedPhaseIndex: Int = 1 // TabView uses 1-based indexing
  @State private var showingStrategyConfirmation: Bool = false
  @State private var advanceTask: Task<Void, Never>?

  var body: some View {
    VStack(spacing: 0) {
      // Emotion context banner
      emotionContextBanner

      // Instruction text
      Text("Select a strategy (optional)")
        .font(.title3)
        .fontWeight(.medium)
        .foregroundColor(.secondary)
        .padding(.top)

      // Strategy layer navigation (layer 0 only)
      if let strategyLayer = flowViewModel.filteredLayers.first(where: { $0.id == 0 }) {
        StrategyPhaseNavigator(
          phases: strategyLayer.phases,
          selectedPhaseIndex: $selectedPhaseIndex,
          onCardTap: { _ in
            // Show strategy picker for this phase
            showingStrategyConfirmation = true
          }
        )
      }
    }
    .onAppear {
      // Set initial phase based on primary emotion
      selectedPhaseIndex = initialPhaseIndex()
    }
    .sheet(isPresented: $showingStrategyConfirmation) {
      if let phase = currentPhase {
        StrategyPickerView(
          phase: phase,
          onSelect: { strategy in
            handleStrategySelection(strategy)
          },
          onCancel: {
            showingStrategyConfirmation = false
          }
        )
        .presentationDetents([.medium, .large])
      }
    }
    .onDisappear {
      advanceTask?.cancel()
      advanceTask = nil
    }
  }

  private var emotionContextBanner: some View {
    HStack(spacing: 12) {
      if let primary = flowViewModel.getPrimaryCurriculum() {
        VStack(spacing: 2) {
          Text("Primary:")
            .font(.caption2)
            .foregroundColor(.secondary)
            .textCase(.uppercase)

          Text(primary.expression)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(primary.dosage == .medicinal ? .green : .red)
        }
      }

      if let secondary = flowViewModel.getSecondaryCurriculum() {
        Divider()
          .frame(height: 30)

        VStack(spacing: 2) {
          Text("Secondary:")
            .font(.caption2)
            .foregroundColor(.secondary)
            .textCase(.uppercase)

          Text(secondary.expression)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(secondary.dosage == .medicinal ? .green : .red)
        }
      }
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 12)
    .frame(maxWidth: .infinity)
    .background(Color.secondary.opacity(0.1))
  }

  /// Determines initial phase index based on primary emotion's phase
  private func initialPhaseIndex() -> Int {
    guard let primaryCurriculum = flowViewModel.getPrimaryCurriculum() else {
      return 1 // Default to first phase
    }

    // Find phase name containing the primary curriculum (search emotion layers only)
    var primaryPhaseName: String?
    for layer in catalog.layers where layer.id != 0 {
      for phase in layer.phases {
        let hasInMedicinal = phase.medicinal.contains { $0.id == primaryCurriculum.id }
        let hasInToxic = phase.toxic.contains { $0.id == primaryCurriculum.id }

        if hasInMedicinal || hasInToxic {
          primaryPhaseName = phase.name
          break
        }
      }
      if primaryPhaseName != nil { break }
    }

    // Find matching phase in strategy layer by name
    guard let phaseName = primaryPhaseName,
          let strategyLayer = flowViewModel.filteredLayers.first(where: { $0.id == 0 }),
          let matchIndex = strategyLayer.phases.firstIndex(where: { $0.name == phaseName })
    else {
      return 1 // Fallback to first phase
    }

    // TabView uses 1-based tag indexing
    return matchIndex + 1
  }

  private var currentPhase: CatalogPhaseModel? {
    guard let strategyLayer = flowViewModel.filteredLayers.first(where: { $0.id == 0 }) else {
      return nil
    }

    // Convert from TabView's 1-based tag to 0-based array index
    let phaseIndex = selectedPhaseIndex - 1
    guard phaseIndex >= 0, phaseIndex < strategyLayer.phases.count else {
      return nil
    }

    return strategyLayer.phases[phaseIndex]
  }

  private func handleStrategySelection(_ strategy: CatalogStrategyModel) {
    // Cancel any pending advancement
    advanceTask?.cancel()

    flowViewModel.selectStrategy(id: strategy.id)
    showingStrategyConfirmation = false

    // Advance to review after brief delay
    advanceTask = Task { @MainActor in
      try? await Task.sleep(nanoseconds: 300_000_000)
      guard !Task.isCancelled, flowViewModel.currentStep == .strategySelection else { return }
      flowViewModel.advanceStep()
    }
  }
}

// MARK: - Strategy Picker Sheet

/// Sheet view for selecting a strategy from a phase.
private struct StrategyPickerView: View {
  let phase: CatalogPhaseModel
  let onSelect: (CatalogStrategyModel) -> Void
  let onCancel: () -> Void

  var body: some View {
    NavigationStack {
      VStack(spacing: 20) {
        // Phase context
        VStack(spacing: 8) {
          Text(phase.name)
            .font(.title2)
            .fontWeight(.bold)
        }
        .padding(.top)

        // Strategy list
        if phase.strategies.isEmpty {
          Text("No strategies available for this phase")
            .foregroundColor(.secondary)
            .padding()
        } else {
          ScrollView {
            VStack(spacing: 12) {
              ForEach(phase.strategies) { strategy in
                Button {
                  onSelect(strategy)
                } label: {
                  HStack {
                    Circle()
                      .fill(colorForStrategy(strategy.color))
                      .frame(width: 12, height: 12)

                    Text(strategy.strategy)
                      .font(.body)
                      .foregroundColor(.primary)
                      .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  .padding(.vertical, 12)
                  .padding(.horizontal, 16)
                  .background(
                    RoundedRectangle(cornerRadius: 10)
                      .fill(Color.secondary.opacity(0.1))
                  )
                }
                .buttonStyle(.plain)
              }
            }
            .padding()
          }
        }

        Spacer()
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", action: onCancel)
        }
      }
      .navigationTitle("Select Strategy")
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  private func colorForStrategy(_ colorName: String) -> Color {
    switch colorName.lowercased() {
    case "blue": .blue
    case "cyan": .cyan
    case "green": .green
    case "yellow": .yellow
    case "orange": .orange
    case "red": .red
    case "purple": .purple
    case "pink": .pink
    default: .gray
    }
  }
}

// MARK: - Strategy Phase Navigator

/// Horizontal scrolling view for navigating through strategy phases
private struct StrategyPhaseNavigator: View {
  let phases: [CatalogPhaseModel]
  @Binding var selectedPhaseIndex: Int
  let onCardTap: (CatalogPhaseModel) -> Void

  var body: some View {
    TabView(selection: $selectedPhaseIndex) {
      ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
        PhaseCard(phase: phase, onTap: { onCardTap(phase) })
          .tag(index + 1) // TabView uses 1-based tags
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .always))
  }
}

/// Card displaying a phase with strategy count
private struct PhaseCard: View {
  let phase: CatalogPhaseModel
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 12) {
        Text(phase.name)
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.primary)

        Text("\(phase.strategies.count) strategies")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.secondary.opacity(0.1))
      .cornerRadius(12)
      .padding()
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Previews

#Preview {
  let catalog = CatalogResponseModel(
    phaseOrder: ["Rising", "Peaking"],
    layers: [
      CatalogLayerModel(
        id: 0,
        color: "Strategies",
        title: "SELF-CARE",
        subtitle: "(Strategies)",
        phases: [
          CatalogPhaseModel(
            id: 1,
            name: "Rising",
            medicinal: [],
            toxic: [],
            strategies: [
              CatalogStrategyModel(id: 10, strategy: "Deep Breathing", color: "Blue"),
              CatalogStrategyModel(id: 11, strategy: "Cold Shower", color: "Cyan"),
            ]
          ),
          CatalogPhaseModel(
            id: 2,
            name: "Peaking",
            medicinal: [],
            toxic: [],
            strategies: [
              CatalogStrategyModel(id: 12, strategy: "Meditation", color: "Green"),
            ]
          ),
        ]
      ),
    ]
  )

  let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)
  viewModel.selectPrimaryCurriculum(id: 1)
  viewModel.advanceStep()
  viewModel.advanceStep()

  return StrategySelectionView(
    catalog: catalog,
    flowViewModel: viewModel
  )
}
