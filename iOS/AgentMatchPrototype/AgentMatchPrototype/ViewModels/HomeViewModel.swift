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
            errorMessage = "서버 연결 실패: 카테고리는 서버(/categories)에서 불러옵니다. 로컬 서버(8000)를 먼저 실행해주세요."
            categories = []
        }
    }
}
