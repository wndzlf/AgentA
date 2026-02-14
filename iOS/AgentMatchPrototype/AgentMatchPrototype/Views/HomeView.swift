import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var query = ""
    @State private var showQuickAgent = false
    @State private var selectedDomain = "all"
    @State private var showAuthGate = false
    @AppStorage("current_user_email") private var currentUserEmail = ""
    @AppStorage("current_user_name") private var currentUserName = ""
    @AppStorage("app_language_code") private var appLanguageCode = "ko"

    private var isEnglish: Bool { !appLanguageCode.lowercased().hasPrefix("ko") }

    private func tr(_ ko: String, _ en: String) -> String {
        isEnglish ? en : ko
    }

    private var filteredCategories: [Category] {
        viewModel.categories.filter { category in
            let matchesDomain = selectedDomain == "all" || (category.domain ?? "unknown") == selectedDomain
            let matchesQuery = query.isEmpty
                || category.name.localizedCaseInsensitiveContains(query)
                || category.summary.localizedCaseInsensitiveContains(query)
                || (category.focus ?? "").localizedCaseInsensitiveContains(query)
            return matchesDomain && matchesQuery
        }
    }

    private var domainOptions: [(id: String, title: String)] {
        let domains = Set(viewModel.categories.map { $0.domain ?? "unknown" })
        let ordered = domains.sorted()
        return [("all", tr("전체", "All"))] + ordered.map { ($0, domainTitle($0)) }
    }

    private var groupedCategories: [(domain: String, items: [Category])] {
        let grouped = Dictionary(grouping: filteredCategories) { $0.domain ?? "unknown" }
        return grouped
            .map { domain, items in
                (domain, items.sorted { $0.name < $1.name })
            }
            .sorted { domainSortRank($0.domain) < domainSortRank($1.domain) }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    AppTheme.pageBackground
                        .ignoresSafeArea()

                    VStack(spacing: 12) {
                        if !domainOptions.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(domainOptions, id: \.id) { domain in
                                        Button {
                                            selectedDomain = domain.id
                                        } label: {
                                            Text(domain.title)
                                                .font(.footnote.weight(.semibold))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule()
                                                        .fill(selectedDomain == domain.id ? AppTheme.tint.opacity(0.22) : Color.secondary.opacity(0.12))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.orange.opacity(0.9))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        List {
                            ForEach(groupedCategories, id: \.domain) { group in
                                Section(domainTitle(group.domain)) {
                                    ForEach(group.items) { category in
                                        NavigationLink(value: category) {
                                            HStack(spacing: 12) {
                                                Image(systemName: category.icon)
                                                    .font(.title3)
                                                    .foregroundStyle(AppTheme.tint)
                                                    .frame(width: 32, height: 32)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(AppTheme.tint.opacity(0.14))
                                                    )
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(category.name)
                                                        .font(.headline)
                                                    Text(category.summary)
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 4)
                                        }
                                        .listRowBackground(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(.ultraThinMaterial)
                                        )
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                        .refreshable {
                            await viewModel.load()
                        }
                    }
                    .padding(.horizontal)

                    DraggableAgentButton(containerSize: proxy.size) {
                        showQuickAgent = true
                    }
                }
            }
            .navigationTitle("Agent Match")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: tr("카테고리 검색", "Search categories"))
            .navigationDestination(for: Category.self) { category in
                CategoryDetailView(category: category)
            }
            .sheet(isPresented: $showQuickAgent) {
                QuickAgentView()
            }
            .fullScreenCover(isPresented: $showAuthGate) {
                EmailAuthView(
                    currentEmail: $currentUserEmail,
                    currentName: $currentUserName
                )
                .interactiveDismissDisabled(true)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section(tr("언어", "Language")) {
                            Button("한국어") {
                                appLanguageCode = "ko"
                                Task { await viewModel.load() }
                            }
                            Button("English") {
                                appLanguageCode = "en"
                                Task { await viewModel.load() }
                            }
                        }
                        Section(tr("계정", "Account")) {
                            if !currentUserEmail.isEmpty {
                                Text(currentUserEmail)
                                Button(tr("로그아웃", "Sign out"), role: .destructive) {
                                    currentUserEmail = ""
                                    currentUserName = ""
                                    showAuthGate = true
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "globe")
                    }
                }
            }
            .task {
                await viewModel.load()
                showAuthGate = currentUserEmail.isEmpty
            }
            .onChange(of: currentUserEmail) { newValue in
                showAuthGate = newValue.isEmpty
            }
            .onChange(of: appLanguageCode) { _ in
                Task { await viewModel.load() }
            }
        }
    }

    private func domainTitle(_ domain: String) -> String {
        if isEnglish {
            switch domain {
            case "people": return "People"
            case "sport": return "Sports"
            case "market": return "Commerce"
            case "service": return "Services"
            case "learning": return "Learning"
            case "job": return "Career"
            default: return "Others"
            }
        }
        switch domain {
        case "people": return "사람/관계"
        case "sport": return "스포츠"
        case "market": return "거래/커머스"
        case "service": return "서비스 의뢰"
        case "learning": return "학습/클래스"
        case "job": return "채용/커리어"
        default: return "기타"
        }
    }

    private func domainSortRank(_ domain: String) -> Int {
        switch domain {
        case "people": return 0
        case "sport": return 1
        case "market": return 2
        case "service": return 3
        case "learning": return 4
        case "job": return 5
        default: return 99
        }
    }
}

private struct EmailAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var currentEmail: String
    @Binding var currentName: String

    @State private var email = ""
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @AppStorage("app_language_code") private var appLanguageCode = "ko"

    private var isEnglish: Bool { !appLanguageCode.lowercased().hasPrefix("ko") }
    private func tr(_ ko: String, _ en: String) -> String { isEnglish ? en : ko }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text(tr("이메일로 시작하기", "Start with Email"))
                    .font(.largeTitle.weight(.bold))
                Text(tr("매칭 요청/수락 후 연락처 공개를 위해 로그인해 주세요.", "Sign in to unlock request, accept, and contact-sharing flows."))
                    .foregroundStyle(.secondary)

                TextField("name@example.com", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                TextField(tr("이름(선택)", "Name (optional)"), text: $name)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task { await signIn() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(tr("계속하기", "Continue"))
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .padding(24)
            .background(AppTheme.pageBackground.ignoresSafeArea())
        }
    }

    private func signIn() async {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedEmail.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let res = try await APIClient.shared.signInEmail(
                email: cleanedEmail,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : name
            )
            currentEmail = res.email
            currentName = res.name
            dismiss()
        } catch {
            errorMessage = tr("로그인 실패. 로컬 서버 상태를 확인해 주세요.", "Sign-in failed. Check local server status.")
        }
    }
}

private struct DraggableAgentButton: View {
    let containerSize: CGSize
    let action: () -> Void

    @State private var basePosition: CGPoint = .zero
    @GestureState private var dragTranslation: CGSize = .zero

    private let buttonSize: CGFloat = 62
    private let margin: CGFloat = 18
    private let tapThreshold: CGFloat = 8

    var body: some View {
        let defaultPoint = defaultPosition(in: containerSize)
        let anchor = basePosition == .zero ? defaultPoint : basePosition
        let currentPoint = clampedPoint(
            CGPoint(
                x: anchor.x + dragTranslation.width,
                y: anchor.y + dragTranslation.height
            ),
            in: containerSize
        )

        Image(systemName: "bolt.fill")
            .font(.title3.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: buttonSize, height: buttonSize)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.tint, AppTheme.tintSoft],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 3)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .contentShape(Circle())
            .position(currentPoint)
            .onAppear {
                if basePosition == .zero {
                    basePosition = defaultPoint
                }
            }
            .onChange(of: containerSize.width) { _ in
                clampBasePosition(in: containerSize)
            }
            .onChange(of: containerSize.height) { _ in
                clampBasePosition(in: containerSize)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragTranslation) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        let start = basePosition == .zero ? defaultPoint : basePosition
                        let endPoint = clampedPoint(
                            CGPoint(
                                x: start.x + value.translation.width,
                                y: start.y + value.translation.height
                            ),
                            in: containerSize
                        )
                        basePosition = endPoint

                        let movedDistance = (
                            value.translation.width * value.translation.width +
                            value.translation.height * value.translation.height
                        ).squareRoot()
                        if movedDistance < tapThreshold {
                            action()
                        }
                    }
            )
            .accessibilityLabel("에이전트에게 바로 물어보기")
    }

    private func defaultPosition(in size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width - (buttonSize / 2) - margin,
            y: size.height - (buttonSize / 2) - margin
        )
    }

    private func clampedPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        let minX = (buttonSize / 2) + margin
        let maxX = size.width - (buttonSize / 2) - margin
        let minY = (buttonSize / 2) + margin
        let maxY = size.height - (buttonSize / 2) - margin
        return CGPoint(
            x: min(max(point.x, minX), maxX),
            y: min(max(point.y, minY), maxY)
        )
    }

    private func clampBasePosition(in size: CGSize) {
        if basePosition == .zero {
            basePosition = defaultPosition(in: size)
            return
        }
        basePosition = clampedPoint(basePosition, in: size)
    }
}
