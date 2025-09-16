import Foundation

struct JournalAPI {
  struct Entry: Codable, Equatable {
    let title: String
    let mood: String
    let note: String
  }

  enum JournalAPIError: LocalizedError {
    case encodingFailed(underlying: Error)
    case invalidResponse
    case requestFailed(statusCode: Int)
    case transportError(underlying: Error)

    var errorDescription: String? {
      switch self {
      case .encodingFailed:
        "We couldn't prepare your journal entry."
      case .invalidResponse:
        "The server returned something unexpected."
      case let .requestFailed(statusCode):
        "The server responded with status code \(statusCode)."
      case .transportError:
        "We couldn't reach the server."
      }
    }

    var failureReason: String? {
      switch self {
      case let .encodingFailed(underlying):
        underlying.localizedDescription
      case let .transportError(underlying):
        underlying.localizedDescription
      case .invalidResponse:
        "The response was not an HTTP response."
      case .requestFailed:
        "The request finished with a non-success status code."
      }
    }
  }

  static let dummyEntry = Entry(
    title: "Daily Reflection",
    mood: "Restorative",
    note: "Felt grounded during breathwork and noted gentle mood shifts."
  )

  private static let defaultEndpoint: URL = {
    guard let url = URL(string: "https://example.com/api/journal") else {
      preconditionFailure("Invalid default journal API URL.")
    }
    return url
  }()

  private let session: URLSession
  private let endpoint: URL

  init(session: URLSession = .shared, endpoint: URL = JournalAPI.defaultEndpoint) {
    self.session = session
    self.endpoint = endpoint
  }

  @discardableResult
  func postJournal() async throws -> Entry {
    let entry = Self.dummyEntry
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]

    do {
      request.httpBody = try encoder.encode(entry)
    } catch {
      throw JournalAPIError.encodingFailed(underlying: error)
    }

    do {
      let (_, response) = try await session.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else {
        throw JournalAPIError.invalidResponse
      }

      guard (200 ..< 300).contains(httpResponse.statusCode) else {
        throw JournalAPIError.requestFailed(statusCode: httpResponse.statusCode)
      }

      return entry
    } catch let apiError as JournalAPIError {
      throw apiError
    } catch {
      throw JournalAPIError.transportError(underlying: error)
    }
  }
}
