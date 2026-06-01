import SwiftUI

/// Single source of truth for the app's transient, root-level
/// presentations (sheets and alerts that float above the main content).
///
/// Historically each presentation owned its own scattered `@State` flag on
/// a leaf or shell view. That scattering is the root cause of the
/// journal-confirmation defect (B2 in
/// `prompts/claude-comm/spec-primary-selector-rebuild.md`): an alert
/// requested from inside a pushed `navigationDestination` is deferred
/// behind the NavigationStack root's competing presentations until the
/// navigation state re-evaluates. Centralizing presentation here lets one
/// host, anchored above the navigation push, render exactly one
/// presentation at a time.
///
/// The coordinator owns every transient root presentation: the shell's
/// former local-`@State` surfaces (`menu`, `onboarding`, `storageError`),
/// the leaf log-confirmation (#406), and the previously publisher-driven
/// journal feedback and flow review (#407). When two presentations contend,
/// the priority/queue policy on `request`/`dismiss` decides ordering —
/// informational feedback queues behind interactive presentations rather
/// than racing them.
@MainActor
final class PresentationCoordinator: ObservableObject {
  /// The presentation currently requested for display, or `.idle`.
  @Published private(set) var active: ActivePresentation = .idle

  /// Presentations queued behind the active one, awaiting `dismiss()`.
  private var pending: [ActivePresentation] = []

  /// Requests that `presentation` be shown.
  ///
  /// Single-active policy (#407, SPEC §11 Q4): exactly one presentation is
  /// visible at a time. A request of strictly higher priority than the
  /// active one preempts it — the displaced presentation is queued, never
  /// dropped — while an equal- or lower-priority request waits in the
  /// queue. `dismiss()` then promotes the highest-priority queued
  /// presentation. This is what lets informational journal feedback queue
  /// politely behind an interactive confirmation instead of racing it.
  func request(_ presentation: ActivePresentation) {
    guard presentation != .idle else { return }
    if active == .idle {
      active = presentation
    } else if Self.priority(of: presentation) > Self.priority(of: active) {
      pending.append(active)
      active = presentation
    } else {
      pending.append(presentation)
    }
  }

  /// Dismisses the active presentation and promotes the highest-priority
  /// queued one (earliest-queued wins ties), or returns to `.idle` when the
  /// queue is empty.
  func dismiss() {
    guard !pending.isEmpty else {
      active = .idle
      return
    }
    var bestIndex = pending.startIndex
    for index in pending.indices
      where Self.priority(of: pending[index]) > Self.priority(of: pending[bestIndex])
    {
      bestIndex = index
    }
    active = pending.remove(at: bestIndex)
  }

  /// A two-way `Bool` binding suitable for `.sheet(isPresented:)` /
  /// `.alert(isPresented:)`. Reads `true` while `presentation` is active;
  /// writing `true` requests it and writing `false` (a "Done" button or a
  /// swipe-dismiss) dismisses it through the queue policy, preserving the
  /// self-dismiss behavior the migrated sheets relied on.
  func isPresented(for presentation: ActivePresentation) -> Binding<Bool> {
    Binding(
      get: { self.active == presentation },
      set: { isPresented in
        if isPresented {
          self.request(presentation)
        } else if self.active == presentation {
          self.dismiss()
        }
      }
    )
  }

  /// Relative display priority; higher wins. A data-loss `storageError`
  /// outranks interactive surfaces, which outrank informational
  /// `journalFeedback`.
  private static func priority(of presentation: ActivePresentation) -> Int {
    switch presentation {
    case .idle: -1
    case .journalFeedback: 0
    case .menu, .onboarding, .logConfirmation, .flowReview: 1
    case .storageError: 2
    }
  }

  /// The set of mutually exclusive root presentations the coordinator can
  /// surface.
  enum ActivePresentation: Equatable {
    /// Nothing is presented. Named `idle` rather than `none` to avoid
    /// visual collision with `Optional.none` at call sites.
    case idle
    case menu
    case onboarding
    case storageError
    /// The "Would you like to log …?" journal confirmation, carrying the
    /// alert copy and the action to perform on "Yes".
    case logConfirmation(LogConfirmationRequest)
    /// Journal-entry feedback (success / queued / failure …), routed here
    /// so it queues behind interactive presentations instead of racing
    /// them.
    case journalFeedback(ContentViewModel.JournalFeedback)
    /// The flow review sheet (`FlowCoordinator.currentStep == .review`).
    case flowReview
  }
}
