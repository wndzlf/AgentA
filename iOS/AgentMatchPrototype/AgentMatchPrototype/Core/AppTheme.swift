import SwiftUI

enum AppTheme {
    static let tint = Color(red: 0.16, green: 0.37, blue: 0.73)
    static let tintSoft = Color(red: 0.37, green: 0.60, blue: 0.87)
    static let bubbleAI = Color(red: 0.93, green: 0.95, blue: 0.99)
    static let bubbleUser = Color(red: 0.87, green: 0.94, blue: 1.0)
    static let scorePill = Color(red: 0.28, green: 0.49, blue: 0.85).opacity(0.2)
    static let tagPill = Color(red: 0.28, green: 0.49, blue: 0.85).opacity(0.12)

    static var pageBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.97, blue: 1.0),
                Color(red: 0.97, green: 0.95, blue: 0.99),
                Color(red: 0.94, green: 0.98, blue: 0.97),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

