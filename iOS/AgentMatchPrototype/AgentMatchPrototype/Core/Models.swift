import Foundation

struct Category: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let summary: String
    let icon: String
}

struct Recommendation: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let tags: [String]
    let score: Double
}

struct AgentResponse: Codable {
    let assistantMessage: String
    let recommendations: [Recommendation]

    enum CodingKeys: String, CodingKey {
        case assistantMessage = "assistant_message"
        case recommendations
    }
}

struct AgentRequest: Codable {
    let categoryID: String?
    let message: String

    enum CodingKeys: String, CodingKey {
        case categoryID = "category_id"
        case message
    }
}

struct BootstrapResponse: Codable {
    let welcomeMessage: String
    let promptHint: String
    let recommendations: [Recommendation]

    enum CodingKeys: String, CodingKey {
        case welcomeMessage = "welcome_message"
        case promptHint = "prompt_hint"
        case recommendations
    }
}
