import Foundation

/// Thrown by `SubmitTimeout.run` when the wrapped operation misses its
/// deadline.
struct SubmitTimeoutError: Error, Equatable {}

/// Races an async operation against a wall-clock deadline.
enum SubmitTimeout {
  /// Deadline applied to a journal submission, co-located with the
  /// mechanism that enforces it.
  static let journalSubmitDeadlineSeconds: Double = 30

  /// Runs `operation`, throwing `SubmitTimeoutError` if it does not finish
  /// within `seconds`. The losing branch is always cancelled, and a real
  /// error from `operation` propagates unchanged rather than being masked
  /// as a timeout.
  ///
  /// `FlowReviewSheet` disables interactive dismissal while a submission is
  /// in flight, so without this an indefinitely-hung `submit()` would leave
  /// the sheet permanently stuck.
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
