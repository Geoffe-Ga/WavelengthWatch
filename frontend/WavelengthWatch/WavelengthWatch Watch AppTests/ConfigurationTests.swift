import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

struct AppConfigurationTests {
  @Test func loadsFromInfoPlistWhenAvailable() {
    let bundle = MockBundle()
    bundle.infoPlistValues["API_BASE_URL"] = "https://api.example.com"

    let config = AppConfiguration(bundle: bundle)

    #expect(config.apiBaseURL.absoluteString == "https://api.example.com")
  }

  @Test func fallsBackToConfigurationPlist() throws {
    let bundle = MockBundle()
    bundle.plistPaths["APIConfiguration"] = createTempPlist(withURL: "https://fallback.example.com")

    let config = AppConfiguration(bundle: bundle)

    #expect(config.apiBaseURL.absoluteString == "https://fallback.example.com")
  }

  @Test func usesPlaceholderWhenNoConfigurationFound() {
    let bundle = MockBundle()

    let config = AppConfiguration(bundle: bundle)

    #expect(config.apiBaseURL.absoluteString == "https://api.not-configured.local")
  }

  @Test func usesPlaceholderWhenURLIsInvalid() {
    let bundle = MockBundle()
    // Use a string that URL(string:) will actually reject (unmatched bracket makes it invalid)
    bundle.infoPlistValues["API_BASE_URL"] = "http://["

    let config = AppConfiguration(bundle: bundle)

    #expect(config.apiBaseURL.absoluteString == "https://api.not-configured.local")
  }

  @Test func trimsWhitespaceFromURL() {
    let bundle = MockBundle()
    bundle.infoPlistValues["API_BASE_URL"] = "  https://api.example.com  "

    let config = AppConfiguration(bundle: bundle)

    #expect(config.apiBaseURL.absoluteString == "https://api.example.com")
  }

  @Test func usesPlaceholderWhenURLIsEmpty() {
    let bundle = MockBundle()
    bundle.infoPlistValues["API_BASE_URL"] = ""

    let config = AppConfiguration(bundle: bundle)

    #expect(config.apiBaseURL.absoluteString == "https://api.not-configured.local")
  }

  private func createTempPlist(withURL url: String) -> String {
    let tempDir = NSTemporaryDirectory()
    let tempFile = URL(fileURLWithPath: tempDir).appendingPathComponent(UUID().uuidString + ".plist")

    let plistDict: [String: Any] = ["API_BASE_URL": url]
    let plistData = try! PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0)
    try! plistData.write(to: tempFile)

    return tempFile.path
  }
}
