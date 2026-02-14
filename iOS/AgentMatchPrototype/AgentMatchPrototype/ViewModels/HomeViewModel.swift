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
            errorMessage = "서버 연결 실패: 로컬 서버(8000)를 먼저 실행해주세요."
            categories = [
                Category(id: "dating", name: "소개팅", summary: "성향 기반 이성 추천", icon: "heart.circle"),
                Category(id: "friend", name: "친구 만들기", summary: "취향/성격 매칭", icon: "person.2.circle"),
                Category(id: "trade", name: "일반 거래", summary: "사고팔기/흥정", icon: "cart.circle"),
                Category(id: "luxury", name: "명품 거래", summary: "브랜드/상태 기반 추천", icon: "sparkles"),
                Category(id: "soccer", name: "축구 매칭", summary: "상대팀/용병 매칭", icon: "sportscourt.circle")
            ]
        }
    }
}
