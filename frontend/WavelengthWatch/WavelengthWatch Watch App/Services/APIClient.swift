import Foundation

enum APIPath {
  static let catalog = "/api/v1/catalog"
  static let journal = "/api/v1/journal"
  static let analyticsOverview = "/api/v1/analytics/overview"
  static let analyticsEmotionalLandscape = "/api/v1/analytics/emotional-landscape"
  static let analyticsSelfCare = "/api/v1/analytics/self-care"
  static let analyticsTemporal = "/api/v1/analytics/temporal"
  static let analyticsGrowth = "/api/v1/analytics/growth"
}

protocol APIClientProtocol {
  func get<T: Decodable>(_ path: String) async throws -> T
  func post<Response: Decodable>(_ path: String, body: some Encodable) async throws -> Response
  func post<Response: Decodable>(
    _ path: String,
    body: some Encodable,
    headers: [String: String]?
  ) async throws -> Response
}

extension APIClientProtocol {
  /// Default implementation that ignores headers and delegates to the 2-parameter post.
  ///
  /// Allows existing mocks/implementations that only define the 2-parameter post
  /// to satisfy the 3-parameter requirement without explicit header handling.
  func post<Response: Decodable>(
    _ path: String,
    body: some Encodable,
    headers _: [String: String]?
  ) async throws -> Response {
    try await post(path, body: body)
  }
}

enum APIClientError: Error {
  case invalidURL(String)
  case transport(Error)
  case badResponse(Int)
}

extension APIClientError {
  /// Whether this error indicates a transient failure that may succeed on retry.
  ///
  /// Retryable errors include:
  /// - Transport errors (network connectivity, timeouts)
  /// - 5xx server errors (server overloaded or transient failure)
  /// - 408 Request Timeout
  /// - 429 Too Many Requests
  ///
  /// Non-retryable errors include:
  /// - Invalid URL construction (permanent)
  /// - 4xx client errors other than 408/429 (validation, auth, not found)
  var isRetryable: Bool {
    switch self {
    case .invalidURL:
      return false
    case .transport:
      return true
    case let .badResponse(status):
      if status >= 500 { return true }
      if status == 408 || status == 429 { return true }
      return false
    }
  }
}

final class APIClient: APIClientProtocol {
  private let baseURL: URL
  private let session: URLSession
  private let decoder: JSONDecoder
  private let encoder: JSONEncoder

  init(baseURL: URL, session: URLSession? = nil, decoder: JSONDecoder = JSONDecoder(), encoder: JSONEncoder = JSONEncoder()) {
    self.baseURL = baseURL
    if let session {
      self.session = session
    } else {
      let configuration = URLSessionConfiguration.ephemeral
      configuration.waitsForConnectivity = false
      configuration.timeoutIntervalForRequest = 10.0
      configuration.timeoutIntervalForResource = 30.0
      self.session = URLSession(configuration: configuration)
    }
    self.decoder = decoder
    self.encoder = encoder
    self.decoder.dateDecodingStrategy = .iso8601
    self.encoder.dateEncodingStrategy = .iso8601
  }

  private func url(for path: String) throws -> URL {
    if let url = URL(string: path, relativeTo: baseURL) {
      return url
    }
    throw APIClientError.invalidURL(path)
  }

  private func decodeResponse<T: Decodable>(data: Data, response: URLResponse) throws -> T {
    guard let http = response as? HTTPURLResponse else {
      throw APIClientError.badResponse(-1)
    }
    guard (200 ... 299).contains(http.statusCode) else {
      throw APIClientError.badResponse(http.statusCode)
    }
    return try decoder.decode(T.self, from: data)
  }

  func get<T: Decodable>(_ path: String) async throws -> T {
    let request = try URLRequest(url: url(for: path))
    do {
      let (data, response) = try await session.data(for: request)
      return try decodeResponse(data: data, response: response)
    } catch let error as APIClientError {
      throw error
    } catch {
      throw APIClientError.transport(error)
    }
  }

  func post<Response: Decodable>(_ path: String, body: some Encodable) async throws -> Response {
    try await post(path, body: body, headers: nil)
  }

  func post<Response: Decodable>(
    _ path: String,
    body: some Encodable,
    headers: [String: String]?
  ) async throws -> Response {
    var request = try URLRequest(url: url(for: path))
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    if let headers {
      for (field, value) in headers {
        request.setValue(value, forHTTPHeaderField: field)
      }
    }
    request.httpBody = try encoder.encode(body)

    do {
      let (data, response) = try await session.data(for: request)
      return try decodeResponse(data: data, response: response)
    } catch let error as APIClientError {
      throw error
    } catch {
      throw APIClientError.transport(error)
    }
  }
}
