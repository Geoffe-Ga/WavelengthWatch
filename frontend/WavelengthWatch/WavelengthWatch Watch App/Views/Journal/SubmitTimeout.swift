import Foundation

/// Thrown by `SubmitTimeout.run` when the wrapped operation misses its
/// deadline.
struct SubmitTimeoutError: Error, Equatable {}

/// Races an async operation against a wall-clock deadline.
///
/// `FlowReviewSheet` disables interactive dismissal while a submission is
/// in flight, so an indefinitely-hung `submit()` would leave the sheet
/// permanently stuck. Wrapping the submission here guarantees it either
/// resolves or throws `SubmitTimeoutError` within `seconds`.
enum SubmitTimeout {
  /// Runs `operation`, throwing `SubmitTimeoutError` if it does not finish
  /// within `seconds`. The operation is cancelled when either branch wins,
  /// and any error it throws propagates unchanged (the timeout never masks
  /// a real failure).
  static func run(
    seconds: Double,
    operation: @escaping @Sendable () async throws -> Void
  ) async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask { try await operation() }
      group.addTask {
        try await Task.sleep(for: .seconds(seconds))
        throw SubmitTimeoutError()
      }
      defer { group.cancelAll() }
      try await group.next()
    }
  }
}
