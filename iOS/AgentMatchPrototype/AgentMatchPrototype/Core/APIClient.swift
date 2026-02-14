import Foundation

enum APIError: Error {
    case invalidURL
    case badResponse
}

final class APIClient {
    static let shared = APIClient()

    // iOS Simulator에서 Mac 로컬 서버 접근 주소
    private let baseURL = "http://127.0.0.1:8000"

    private init() {}

    func fetchCategories() async throws -> [Category] {
        guard let url = URL(string: "\(baseURL)/categories") else { throw APIError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badResponse
        }
        return try JSONDecoder().decode([Category].self, from: data)
    }

    func fetchBootstrap(categoryID: String) async throws -> BootstrapResponse {
        guard let url = URL(string: "\(baseURL)/categories/\(categoryID)/bootstrap") else { throw APIError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badResponse
        }
        return try JSONDecoder().decode(BootstrapResponse.self, from: data)
    }

    func askAgent(categoryID: String?, message: String) async throws -> AgentResponse {
        guard let url = URL(string: "\(baseURL)/agent/ask") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(AgentRequest(categoryID: categoryID, message: message))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badResponse
        }
        return try JSONDecoder().decode(AgentResponse.self, from: data)
    }
}
