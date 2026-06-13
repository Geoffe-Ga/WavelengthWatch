import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

/// Tests for `PresentationCoordinator` — the single source of truth for
/// root-level transient presentations. The coordinator is pure state with
/// no view dependency, so these exercise the request/dismiss transitions
/// and the `isPresented(for:)` binding contract directly.
@MainActor
struct PresentationCoordinatorTests {
  // MARK: - Initial state

  @Test("coordinator starts with no active presentation")
  func initialization_isNone() {
    let coordinator = PresentationCoordinator()

    #expect(coordinator.active == .idle)
  }

  // MARK: - request / dismiss

  @Test("request activates the requested presentation")
  func request_activatesPresentation() {
    let coordinator = PresentationCoordinator()

    coordinator.request(.menu)

    #expect(coordinator.active == .menu)
  }

  @Test("an equal-priority second request queues behind the active one")
  func request_equalPriorityQueuesBehindActive() {
    let coordinator = PresentationCoordinator()

    coordinator.request(.menu)
    // `.onboarding` shares `.menu`'s priority (1), so under the #407
    // priority/queue policy it queues rather than replacing the active
    // presentation. (This supersedes the old "skeleton" replace policy.)
    coordinator.request(.onboarding)

    #expect(coordinator.active == .menu)
    coordinator.dismiss()
    #expect(coordinator.active == .onboarding) // queued request surfaces on dismiss
  }

  @Test("dismiss returns to none")
  func dismiss_returnsToNone() {
    let coordinator = PresentationCoordinator()
    coordinator.request(.storageError(reason: nil))

    coordinator.dismiss()

    #expect(coordinator.active == .idle)
  }

  @Test("dismiss while already idle is a no-op")
  func dismiss_whenAlreadyIdle_isNoOp() {
    let coordinator = PresentationCoordinator()

    coordinator.dismiss()

    #expect(coordinator.active == .idle)
  }

  // MARK: - isPresented(for:) binding

  @Test("isPresented reads true only for the active presentation")
  func isPresented_readsTrueForActive() {
    let coordinator = PresentationCoordinator()
    coordinator.request(.menu)

    #expect(coordinator.isPresented(for: .menu).wrappedValue == true)
    #expect(coordinator.isPresented(for: .onboarding).wrappedValue == false)
    #expect(coordinator.isPresented(for: .storageError(reason: nil)).wrappedValue == false)
  }

  @Test("writing true through the binding activates that presentation")
  func isPresented_writeTrue_activates() {
    let coordinator = PresentationCoordinator()

    coordinator.isPresented(for: .onboarding).wrappedValue = true

    #expect(coordinator.active == .onboarding)
  }

  @Test("writing false through the binding for the active presentation dismisses it")
  func isPresented_writeFalse_dismissesActive() {
    let coordinator = PresentationCoordinator()
    coordinator.request(.menu)

    coordinator.isPresented(for: .menu).wrappedValue = false

    #expect(coordinator.active == .idle)
  }

  @Test("writing false for a non-active presentation does not clobber the active one")
  func isPresented_writeFalse_forOther_isNoOp() {
    let coordinator = PresentationCoordinator()
    coordinator.request(.menu)

    // A stale binding from a different surface writing false must not
    // dismiss the menu that is genuinely active.
    coordinator.isPresented(for: .onboarding).wrappedValue = false

    #expect(coordinator.active == .menu)
  }
}
