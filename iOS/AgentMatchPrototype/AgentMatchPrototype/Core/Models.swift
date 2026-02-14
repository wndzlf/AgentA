import Foundation

struct Category: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let summary: String
    let icon: String
    let domain: String?
    let focus: String?
}

struct Recommendation: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let tags: [String]
    let score: Double
    let detail: String?
    let imageURLs: [String]?
    let ownerName: String?
    let ownerEmailMasked: String?
    let ownerPhoneMasked: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case tags
        case score
        case detail
        case imageURLs = "image_urls"
        case ownerName = "owner_name"
        case ownerEmailMasked = "owner_email_masked"
        case ownerPhoneMasked = "owner_phone_masked"
    }
}

struct AgentMode: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String
}

struct CategoryField: Identifiable, Codable, Hashable {
    let id: String
    let label: String
    let hint: String
    let keywords: [String]
}

struct CategorySchemaResponse: Codable {
    let categoryID: String
    let mode: String
    let requiredFields: [CategoryField]
    let examples: [String]

    enum CodingKeys: String, CodingKey {
        case categoryID = "category_id"
        case mode
        case requiredFields = "required_fields"
        case examples
    }
}

struct RouteCandidate: Codable, Hashable {
    let categoryID: String
    let categoryName: String
    let domain: String
    let score: Double
    let reason: String
    let suggestedMode: String

    enum CodingKeys: String, CodingKey {
        case categoryID = "category_id"
        case categoryName = "category_name"
        case domain
        case score
        case reason
        case suggestedMode = "suggested_mode"
    }
}

struct RouteResponse: Codable {
    let selected: RouteCandidate?
    let candidates: [RouteCandidate]
}

struct ActionHistoryItem: Codable, Hashable {
    let status: String
    let note: String?
    let at: String
}

struct MatchAction: Identifiable, Codable, Hashable {
    let id: String
    let categoryID: String
    let recommendationID: String
    let recommendationTitle: String
    let recommendationSubtitle: String
    let status: String
    let actorRole: String?
    let requesterEmail: String?
    let requesterName: String?
    let ownerEmailMasked: String?
    let allowedActions: [String]
    let contactUnlocked: Bool?
    let counterpartName: String?
    let counterpartEmail: String?
    let counterpartPhone: String?
    let note: String?
    let createdAt: String
    let updatedAt: String
    let history: [ActionHistoryItem]

    enum CodingKeys: String, CodingKey {
        case id
        case categoryID = "category_id"
        case recommendationID = "recommendation_id"
        case recommendationTitle = "recommendation_title"
        case recommendationSubtitle = "recommendation_subtitle"
        case status
        case actorRole = "actor_role"
        case requesterEmail = "requester_email"
        case requesterName = "requester_name"
        case ownerEmailMasked = "owner_email_masked"
        case allowedActions = "allowed_actions"
        case contactUnlocked = "contact_unlocked"
        case counterpartName = "counterpart_name"
        case counterpartEmail = "counterpart_email"
        case counterpartPhone = "counterpart_phone"
        case note
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case history
    }
}

struct ActionListResponse: Codable {
    let actions: [MatchAction]
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
    let userEmail: String?
    let userName: String?

    enum CodingKeys: String, CodingKey {
        case categoryID = "category_id"
        case mode
        case message
        case userEmail = "user_email"
        case userName = "user_name"
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

struct RecommendationDetailResponse: Codable {
    let recommendation: Recommendation
    let action: MatchAction?
}

struct EmailAuthRequest: Codable {
    let email: String
    let name: String?
}

struct EmailAuthResponse: Codable {
    let email: String
    let name: String
    let created: Bool
}
