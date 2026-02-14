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
                Category(id: "soccer", name: "축구 매칭", summary: "상대팀/용병 매칭", icon: "sportscourt.circle"),
                Category(id: "futsal", name: "풋살 매칭", summary: "근거리 풋살 팀 매칭", icon: "figure.indoor.soccer"),
                Category(id: "roommate", name: "룸메이트", summary: "주거/생활 패턴 매칭", icon: "house.and.person"),
                Category(id: "pet", name: "반려동물", summary: "입양/보호 매칭", icon: "pawprint.circle"),
                Category(id: "study", name: "스터디", summary: "학습 목표 기반 매칭", icon: "book.circle"),
                Category(id: "mentor", name: "멘토링", summary: "멘토/멘티 매칭", icon: "graduationcap.circle"),
                Category(id: "freelance", name: "프리랜서", summary: "프로젝트/전문가 매칭", icon: "briefcase.circle"),
                Category(id: "job", name: "구인구직", summary: "채용/지원 매칭", icon: "building.2.crop.circle"),
                Category(id: "ticket", name: "티켓 양도", summary: "공연/스포츠 티켓 거래", icon: "ticket"),
                Category(id: "travelmate", name: "여행 메이트", summary: "일정/취향 기반 동행", icon: "airplane.circle"),
                Category(id: "usedcar", name: "중고차 거래", summary: "차량 조건 기반 거래", icon: "car.circle"),
                Category(id: "realestate", name: "부동산", summary: "매물/조건 기반 매칭", icon: "building.columns.circle"),
                Category(id: "gaming", name: "게임 파티", summary: "게임/티어 기반 팀 매칭", icon: "gamecontroller.circle"),
                Category(id: "language", name: "언어교환", summary: "언어/시간대 기반 파트너", icon: "globe"),
                Category(id: "parenting", name: "육아 돌봄", summary: "돌봄 요청/도우미 매칭", icon: "figure.and.child.holdinghands"),
                Category(id: "class", name: "원데이 클래스", summary: "클래스 등록/수강 매칭", icon: "paintpalette")
            ]
        }
    }
}
