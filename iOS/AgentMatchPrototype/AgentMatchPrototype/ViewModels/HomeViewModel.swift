import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            categories = try await APIClient.shared.fetchCategories()
            errorMessage = nil
        } catch {
            let language = (UserDefaults.standard.string(forKey: "app_language_code") ?? "ko").lowercased()
            if language.hasPrefix("ko") {
                errorMessage = "서버 연결 실패: 카테고리는 서버(/categories)에서 불러옵니다. 로컬 서버(8000)를 먼저 실행해주세요."
            } else {
                errorMessage = "Server connection failed: categories are loaded from /categories. Start local server on port 8000."
            }
            categories = []
        }
    }
}
