import Foundation

struct AppConfiguration {
  let apiBaseURL: URL

  init(bundle: Bundle = .main) {
    if let urlString = bundle.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
       let url = URL(string: urlString), !urlString.isEmpty
    {
      self.apiBaseURL = url
    } else {
      self.apiBaseURL = URL(string: "https://example.com")!
    }
  }
}
