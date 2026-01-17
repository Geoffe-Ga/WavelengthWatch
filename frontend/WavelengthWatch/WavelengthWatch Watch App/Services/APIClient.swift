import Foundation

enum APIPath {
  static let catalog = "/api/v1/catalog"
  static let journal = "/api/v1/journal"
  static let analyticsOverview = "/api/v1/analytics/overview"
  static let analyticsEmotionalLandscape = "/api/v1/analytics/emotional-landscape"
  static let analyticsSelfCare = "/api/v1/analytics/self-care"
}

protocol APIClientProtocol {
  func get<T: Decodable>(_ path: String) async throws -> T
  func post<Response: Decodable>(_ path: String, body: some Encodable) async throws -> Response
}

enum APIClientError: Error {
  case invalidURL(String)
  case transport(Error)
  case badResponse(Int)
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
    var request = try URLRequest(url: url(for: path))
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
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
