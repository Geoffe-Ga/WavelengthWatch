import SwiftUI

/// View for selecting the primary emotion in the journal flow.
///
/// This view displays only emotion layers (excluding strategies layer 0),
/// allows the user to browse phases, and presents a dosage picker when
/// tapping on a phase card.
@MainActor
struct PrimaryEmotionSelectionView: View {
  let catalog: CatalogResponseModel
  @ObservedObject var flowViewModel: JournalFlowViewModel

  @State private var selectedLayerIndex: Int = 0
  @State private var selectedPhaseIndex: Int = 0
  @State private var showingDosagePicker: Bool = false

  var body: some View {
    VStack(spacing: 0) {
      // Instruction text
      Text("How are you feeling?")
        .font(.title3)
        .fontWeight(.medium)
        .foregroundColor(.secondary)
        .padding(.top)

      // Filtered layer navigation (emotions only)
      FilteredLayerNavigationView(
        layers: flowViewModel.filteredLayers,
        phaseOrder: catalog.phaseOrder,
        selectedLayerIndex: $selectedLayerIndex,
        selectedPhaseIndex: $selectedPhaseIndex,
        onPhaseCardTap: {
          showingDosagePicker = true
        }
      )
    }
    .sheet(isPresented: $showingDosagePicker) {
      if let phase = currentPhase, let layer = currentLayer {
        DosagePickerView(
          phase: phase,
          layer: layer,
          onSelect: { curriculum in
            flowViewModel.selectPrimaryCurriculum(id: curriculum.id)
            showingDosagePicker = false
            // Advance to next step after brief delay to allow sheet dismissal animation
            Task { @MainActor in
              try? await Task.sleep(nanoseconds: 300_000_000)
              flowViewModel.advanceStep()
            }
          },
          onCancel: {
            showingDosagePicker = false
          }
        )
        .presentationDetents([.medium, .large])
      }
    }
  }

  private var currentLayer: CatalogLayerModel? {
    guard selectedLayerIndex < flowViewModel.filteredLayers.count else { return nil }
    return flowViewModel.filteredLayers[selectedLayerIndex]
  }

  private var currentPhase: CatalogPhaseModel? {
    guard let layer = currentLayer else { return nil }
    let phaseIndex = selectedPhaseIndex - 1 // Adjust for 1-based indexing
    guard phaseIndex >= 0, phaseIndex < layer.phases.count else { return nil }
    return layer.phases[phaseIndex]
  }
}

// MARK: - Dosage Picker Sheet

/// Sheet view for selecting medicinal or toxic dosage from a phase.
private struct DosagePickerView: View {
  let phase: CatalogPhaseModel
  let layer: CatalogLayerModel?
  let onSelect: (CatalogCurriculumEntryModel) -> Void
  let onCancel: () -> Void

  var body: some View {
    NavigationStack {
      VStack(spacing: 20) {
        // Phase context
        VStack(spacing: 8) {
          if let layer {
            Text(layer.title)
              .font(.caption)
              .foregroundColor(.secondary)
              .textCase(.uppercase)
          }

          Text(phase.name)
            .font(.title2)
            .fontWeight(.bold)
        }
        .padding(.top)

        // Dosage options
        VStack(spacing: 12) {
          if !phase.medicinal.isEmpty {
            DosageSection(
              title: "Medicinal",
              entries: phase.medicinal,
              color: .green,
              onSelect: onSelect
            )
          }

          if !phase.toxic.isEmpty {
            DosageSection(
              title: "Toxic",
              entries: phase.toxic,
              color: .red,
              onSelect: onSelect
            )
          }
        }
        .padding()

        Spacer()
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", action: onCancel)
        }
      }
      .navigationTitle("Select Dosage")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

/// Section displaying curriculum entries for a specific dosage type.
private struct DosageSection: View {
  let title: String
  let entries: [CatalogCurriculumEntryModel]
  let color: Color
  let onSelect: (CatalogCurriculumEntryModel) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 4) {
        Circle()
          .fill(color)
          .frame(width: 6, height: 6)

        Text(title)
          .font(.caption)
          .fontWeight(.semibold)
          .textCase(.uppercase)
          .foregroundColor(.secondary)
      }

      ForEach(entries) { entry in
        Button {
          onSelect(entry)
        } label: {
          HStack {
            Text(entry.expression)
              .font(.body)
              .foregroundColor(.primary)
              .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          .padding(.vertical, 8)
          .padding(.horizontal, 12)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.secondary.opacity(0.1))
          )
        }
        .buttonStyle(.plain)
      }
    }
  }
}

// MARK: - Previews

#Preview {
  let catalog = CatalogResponseModel(
    phaseOrder: ["Rising"],
    layers: [
      CatalogLayerModel(
        id: 3,
        color: "Red",
        title: "RED",
        subtitle: "(Power)",
        phases: [
          CatalogPhaseModel(
            id: 1,
            name: "Rising",
            medicinal: [
              CatalogCurriculumEntryModel(id: 1, dosage: .medicinal, expression: "Confident"),
            ],
            toxic: [
              CatalogCurriculumEntryModel(id: 2, dosage: .toxic, expression: "Aggressive"),
            ],
            strategies: []
          ),
        ]
      ),
    ]
  )

  PrimaryEmotionSelectionView(
    catalog: catalog,
    flowViewModel: JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)
  )
}
