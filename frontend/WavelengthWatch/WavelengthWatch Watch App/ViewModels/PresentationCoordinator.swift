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
/// This skeleton (issue #405) owns the three presentations that were
/// previously plain local `@State` booleans on the shell — `menu`,
/// `onboarding`, and `storageError`. The publisher-driven surfaces
/// (journal feedback, flow review) and the leaf log-confirmation migrate
/// onto the same coordinator in #406 / #407 as their owners are
/// retargeted, at which point the conflict policy graduates from the
/// simple "replace" used here to the queue/priority rules in #407.
@MainActor
final class PresentationCoordinator: ObservableObject {
  /// The presentation currently requested for display, or `.none`.
  @Published private(set) var active: ActivePresentation = .none

  /// Requests that `presentation` become the active presentation.
  ///
  /// Skeleton policy: a new request replaces whatever is active. Issue
  /// #407 refines this into a priority/queue policy so that, e.g., a
  /// data-loss `storageError` is never silently dropped by a lower-value
  /// request.
  func request(_ presentation: ActivePresentation) {
    active = presentation
  }

  /// Dismisses the active presentation, returning to `.none`.
  func dismiss() {
    active = .none
  }

  /// A two-way `Bool` binding suitable for `.sheet(isPresented:)` /
  /// `.alert(isPresented:)`. Reads `true` while `presentation` is active;
  /// writing `false` (a "Done" button or a swipe-dismiss) clears it,
  /// preserving the self-dismiss behavior the migrated sheets relied on.
  func isPresented(for presentation: ActivePresentation) -> Binding<Bool> {
    Binding(
      get: { self.active == presentation },
      set: { isPresented in
        if isPresented {
          self.active = presentation
        } else if self.active == presentation {
          self.active = .none
        }
      }
    )
  }

  /// The set of mutually exclusive root presentations the coordinator can
  /// surface. Cases are added here as later issues fold their owners in.
  enum ActivePresentation: Equatable {
    case none
    case menu
    case onboarding
    case storageError
  }
}
