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

struct AgentMode: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String
}

struct AgentResponse: Codable {
    let assistantMessage: String
    let activeMode: String?
    let actionResult: String?
    let recommendations: [Recommendation]

    enum CodingKeys: String, CodingKey {
        case assistantMessage = "assistant_message"
        case activeMode = "active_mode"
        case actionResult = "action_result"
        case recommendations
    }
}

struct AgentRequest: Codable {
    let categoryID: String?
    let mode: String?
    let message: String

    enum CodingKeys: String, CodingKey {
        case categoryID = "category_id"
        case mode
        case message
    }
}

struct BootstrapResponse: Codable {
    let welcomeMessage: String
    let promptHint: String
    let activeMode: String
    let modes: [AgentMode]
    let recommendations: [Recommendation]

    enum CodingKeys: String, CodingKey {
        case welcomeMessage = "welcome_message"
        case promptHint = "prompt_hint"
        case activeMode = "active_mode"
        case modes
        case recommendations
    }
}
