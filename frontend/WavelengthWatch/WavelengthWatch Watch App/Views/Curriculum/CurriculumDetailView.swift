import SwiftUI

struct CurriculumDetailView: View {
  /// Clear Light layer ID constant (layer 10)
  private static let clearLightLayerID = 10

  let layer: CatalogLayerModel
  let phase: CatalogPhaseModel
  let color: Color
  @EnvironmentObject private var viewModel: ContentViewModel
  @EnvironmentObject private var flowCoordinator: FlowCoordinator
  @Environment(\.isShowingDetailView) private var isShowingDetailView

  /// Cached medicinal emotions (computed once on appear for performance)
  @State private var cachedMedicinalEmotions: [LayeredEmotion] = []
  /// Cached toxic emotions (computed once on appear for performance)
  @State private var cachedToxicEmotions: [LayeredEmotion] = []

  /// Whether this is the Clear Light layer (shows all emotions from all layers)
  private var isClearLight: Bool {
    layer.id == Self.clearLightLayerID
  }

  /// Computes all medicinal emotions from all layers (for Clear Light display)
  private func computeAllMedicinalEmotions() -> [LayeredEmotion] {
    var emotions: [LayeredEmotion] = []
    for sourceLayer in viewModel.layers where sourceLayer.id != 0 && sourceLayer.id != Self.clearLightLayerID {
      for sourcePhase in sourceLayer.phases where sourcePhase.name == phase.name {
        for entry in sourcePhase.medicinal {
          emotions.append(LayeredEmotion(
            layerId: sourceLayer.id,
            entry: entry,
            layerTitle: sourceLayer.title,
            layerColor: sourceLayer.color
          ))
        }
      }
    }
    return emotions
  }

  /// Computes all toxic emotions from all layers (for Clear Light display)
  private func computeAllToxicEmotions() -> [LayeredEmotion] {
    var emotions: [LayeredEmotion] = []
    for sourceLayer in viewModel.layers where sourceLayer.id != 0 && sourceLayer.id != Self.clearLightLayerID {
      for sourcePhase in sourceLayer.phases where sourcePhase.name == phase.name {
        for entry in sourcePhase.toxic {
          emotions.append(LayeredEmotion(
            layerId: sourceLayer.id,
            entry: entry,
            layerTitle: sourceLayer.title,
            layerColor: sourceLayer.color
          ))
        }
      }
    }
    return emotions
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        if isClearLight {
          // Clear Light header - shows that all emotions are displayed
          VStack(spacing: 4) {
            Text(phase.name)
              .font(.title2)
              .fontWeight(.thin)
              .foregroundColor(.white)
            Text("All Emotions")
              .font(.caption)
              .foregroundColor(.white.opacity(0.6))
          }
          .padding(.top, 8)

          // Medicinal section with all emotions from all layers
          if !cachedMedicinalEmotions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
              Text("MEDICINAL")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .tracking(1.5)
                .padding(.horizontal, 16)

              ForEach(cachedMedicinalEmotions) { emotion in
                ClearLightEmotionCard(
                  emotion: emotion,
                  dosageType: .medicinal
                )
              }
            }
          }

          // Toxic section with all emotions from all layers
          if !cachedToxicEmotions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
              Text("TOXIC")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .tracking(1.5)
                .padding(.horizontal, 16)

              ForEach(cachedToxicEmotions) { emotion in
                ClearLightEmotionCard(
                  emotion: emotion,
                  dosageType: .toxic
                )
              }
            }
          }
        } else {
          // Normal layer display
          Text(phase.name)
            .font(.title2)
            .fontWeight(.thin)
            .foregroundColor(.white)
            .padding(.top, 8)

          VStack(spacing: 20) {
            ForEach(phase.medicinal) { entry in
              CurriculumCard(
                title: "MEDICINE",
                expression: entry.expression,
                accent: color,
                actionTitle: "Log Medicinal",
                entry: entry
              )
            }

            ForEach(phase.toxic) { entry in
              CurriculumCard(
                title: "TOXIC",
                expression: entry.expression,
                accent: .red,
                actionTitle: "Log Toxic",
                entry: entry
              )
            }
          }
          .padding(.horizontal, 8)

          if !phase.strategies.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
              Text("STRATEGIES")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .tracking(1.5)
              ForEach(phase.strategies) { strategy in
                StrategyCard(
                  strategy: strategy,
                  color: color,
                  phase: phase
                )
              }
            }
            .padding(.horizontal, 16)
          }
        }
      }
      .padding(.vertical, 16)
    }
    .background(
      LinearGradient(
        gradient: Gradient(colors: [Color.black, Color.black.opacity(0.8)]),
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .onAppear {
      isShowingDetailView.wrappedValue = true
      // Cache aggregated emotions once for Clear Light (avoids re-computation on every render)
      if isClearLight {
        cachedMedicinalEmotions = computeAllMedicinalEmotions()
        cachedToxicEmotions = computeAllToxicEmotions()
      }
    }
    .onDisappear {
      isShowingDetailView.wrappedValue = false
      // Clear cached emotions to prevent stale data and memory bloat
      cachedMedicinalEmotions = []
      cachedToxicEmotions = []
    }
  }
}
