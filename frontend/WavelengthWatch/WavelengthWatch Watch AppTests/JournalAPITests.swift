import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

private final class URLProtocolSpy: URLProtocol {
  enum SpyError: Error {
    case missingHandler
  }

  static var requestHandler: ((URLRequest) throws -> (Data, URLResponse))?

  static func reset() {
    requestHandler = nil
  }

  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard let handler = Self.requestHandler else {
      client?.urlProtocol(self, didFailWithError: SpyError.missingHandler)
      return
    }

    do {
      let (data, response) = try handler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}

enum JournalAPITestsError: Error {
  case missingRequest
  case missingBody
}

struct JournalAPITests {
  @Test func postJournalBuildsExpectedRequest() async throws {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolSpy.self]
    let session = URLSession(configuration: configuration)
    let endpoint = URL(string: "https://example.com/journal")!
    let api = JournalAPI(session: session, endpoint: endpoint)

    var capturedRequest: URLRequest?
    URLProtocolSpy.requestHandler = { request in
      capturedRequest = request
      let response = HTTPURLResponse(
        url: endpoint,
        statusCode: 201,
        httpVersion: nil,
        headerFields: nil
      )!
      return (Data(), response)
    }
    defer { URLProtocolSpy.reset() }

    let entry = try await api.postJournal()
    #expect(entry == JournalAPI.dummyEntry)

    guard let request = capturedRequest else {
      throw JournalAPITestsError.missingRequest
    }
    #expect(request.httpMethod == "POST")
    #expect(request.url == endpoint)
    #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

    guard let body = request.httpBody else {
      throw JournalAPITestsError.missingBody
    }
    let decoded = try JSONDecoder().decode(JournalAPI.Entry.self, from: body)
    #expect(decoded == JournalAPI.dummyEntry)
  }

  @Test func postJournalPropagatesRequestFailures() async throws {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolSpy.self]
    let session = URLSession(configuration: configuration)
    let endpoint = URL(string: "https://example.com/journal")!
    let api = JournalAPI(session: session, endpoint: endpoint)

    URLProtocolSpy.requestHandler = { _ in
      let response = HTTPURLResponse(
        url: endpoint,
        statusCode: 500,
        httpVersion: nil,
        headerFields: nil
      )!
      return (Data(), response)
    }
    defer { URLProtocolSpy.reset() }

    var recordedError: JournalAPI.JournalAPIError?
    do {
      _ = try await api.postJournal()
    } catch let error as JournalAPI.JournalAPIError {
      recordedError = error
    }

    guard let error = recordedError else {
      #expect(false)
      return
    }

    switch error {
    case .requestFailed(let statusCode):
      #expect(statusCode == 500)
    default:
      #expect(false)
    }
  }
}
