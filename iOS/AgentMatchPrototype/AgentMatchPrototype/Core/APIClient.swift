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

    private var appLanguage: String {
        let raw = UserDefaults.standard.string(forKey: "app_language_code") ?? "ko"
        return raw.lowercased().hasPrefix("ko") ? "ko" : "en"
    }

    private func makeURL(path: String, queryItems: [URLQueryItem] = []) -> URL? {
        var components = URLComponents(string: "\(baseURL)\(path)")
        var items = queryItems
        items.append(URLQueryItem(name: "lang", value: appLanguage))
        components?.queryItems = items
        return components?.url
    }

    func fetchCategories() async throws -> [Category] {
        guard let url = makeURL(path: "/categories") else { throw APIError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badResponse
        }
        return try JSONDecoder().decode([Category].self, from: data)
    }

    func fetchBootstrap(categoryID: String, mode: String? = nil) async throws -> BootstrapResponse {
        var items: [URLQueryItem] = []
        if let mode, !mode.isEmpty {
            items.append(URLQueryItem(name: "mode", value: mode))
        }
        guard let url = makeURL(path: "/categories/\(categoryID)/bootstrap", queryItems: items) else { throw APIError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badResponse
        }
        return try JSONDecoder().decode(BootstrapResponse.self, from: data)
    }

    func fetchCategorySchema(categoryID: String, mode: String? = nil) async throws -> CategorySchemaResponse {
        var items: [URLQueryItem] = []
        if let mode, !mode.isEmpty {
            items.append(URLQueryItem(name: "mode", value: mode))
        }
        guard let url = makeURL(path: "/categories/\(categoryID)/schema", queryItems: items) else { throw APIError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badResponse
        }
        return try JSONDecoder().decode(CategorySchemaResponse.self, from: data)
    }

    func askAgent(
        categoryID: String?,
        mode: String? = nil,
        message: String,
        userEmail: String? = nil,
        userName: String? = nil
    ) async throws -> AgentResponse {
        guard let url = makeURL(path: "/agent/ask") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            AgentRequest(
                categoryID: categoryID,
                mode: mode,
                message: message,
                userEmail: userEmail,
                userName: userName
            )
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badResponse
        }
        return try JSONDecoder().decode(AgentResponse.self, from: data)
    }

    func routeAgent(message: String, limit: Int = 5) async throws -> RouteResponse {
        guard let url = makeURL(path: "/agent/route") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(
            withJSONObject: ["message": message, "limit": limit],
            options: []
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badResponse
        }
        return try JSONDecoder().decode(RouteResponse.self, from: data)
    }

    func fetchActions(categoryID: String? = nil, viewerEmail: String? = nil) async throws -> [MatchAction] {
        var items: [URLQueryItem] = []
        if let categoryID, !categoryID.isEmpty {
            items.append(URLQueryItem(name: "category_id", value: categoryID))
        }
        if let viewerEmail, !viewerEmail.isEmpty {
            items.append(URLQueryItem(name: "viewer_email", value: viewerEmail))
        }
        guard let url = makeURL(path: "/actions", queryItems: items) else { throw APIError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badResponse
        }
        let body = try JSONDecoder().decode(ActionListResponse.self, from: data)
        return body.actions
    }

    func requestAction(
        categoryID: String,
        recommendation: Recommendation,
        requesterEmail: String,
        requesterName: String? = nil,
        note: String? = nil
    ) async throws -> MatchAction {
        guard let url = makeURL(path: "/actions/request") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(
            withJSONObject: [
                "category_id": categoryID,
                "recommendation_id": recommendation.id,
                "recommendation_title": recommendation.title,
                "recommendation_subtitle": recommendation.subtitle,
                "requester_email": requesterEmail,
                "requester_name": requesterName ?? "",
                "note": note ?? ""
            ],
            options: []
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badResponse
        }
        return try JSONDecoder().decode(MatchAction.self, from: data)
    }

    func transitionAction(
        actionID: String,
        command: String,
        actorEmail: String,
        note: String? = nil
    ) async throws -> MatchAction {
        guard let url = makeURL(path: "/actions/\(actionID)/transition") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(
            withJSONObject: [
                "action": command,
                "actor_email": actorEmail,
                "note": note ?? ""
            ],
            options: []
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badResponse
        }
        return try JSONDecoder().decode(MatchAction.self, from: data)
    }

    func fetchRecommendationDetail(
        categoryID: String,
        recommendationID: String,
        viewerEmail: String
    ) async throws -> RecommendationDetailResponse {
        let items = [URLQueryItem(name: "viewer_email", value: viewerEmail)]
        guard let url = makeURL(
            path: "/categories/\(categoryID)/recommendations/\(recommendationID)",
            queryItems: items
        ) else { throw APIError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badResponse
        }
        return try JSONDecoder().decode(RecommendationDetailResponse.self, from: data)
    }

    func signInEmail(email: String, name: String?) async throws -> EmailAuthResponse {
        guard let url = makeURL(path: "/auth/email") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(EmailAuthRequest(email: email, name: name))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.badResponse
        }
        return try JSONDecoder().decode(EmailAuthResponse.self, from: data)
    }
}
