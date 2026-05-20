import Testing
@testable import WavelengthWatch_Watch_App

/// Coverage for `SubmitTimeout.run` — the deadline race that keeps a hung
/// journal submission from stranding `FlowReviewSheet` (#341).
struct SubmitTimeoutTests {
  private struct ProbeError: Error, Equatable {}

  @Test("an operation finishing before the deadline does not throw")
  func fastOperation_completes() async throws {
    try await SubmitTimeout.run(seconds: 5) {}
  }

  @Test("an operation exceeding the deadline throws SubmitTimeoutError")
  func slowOperation_timesOut() async {
    await #expect(throws: SubmitTimeoutError.self) {
      try await SubmitTimeout.run(seconds: 0.05) {
        try await Task.sleep(for: .seconds(10))
      }
    }
  }

  @Test("an operation error propagates instead of being masked as a timeout")
  func operationError_propagates() async {
    await #expect(throws: ProbeError.self) {
      try await SubmitTimeout.run(seconds: 5) {
        throw ProbeError()
      }
    }
  }
}
