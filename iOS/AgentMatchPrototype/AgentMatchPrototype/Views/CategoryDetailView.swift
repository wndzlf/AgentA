import AVFoundation
import PhotosUI
import Speech
import SwiftUI
import UIKit

struct CategoryDetailView: View {
    let category: Category

    @State private var modes: [AgentMode] = []
    @State private var activeModeID = ""
    @State private var promptHint = ""
    @State private var input = ""
    @State private var messages: [String] = []
    @State private var recommendations: [Recommendation] = []
    @State private var actionByRecommendationID: [String: MatchAction] = [:]
    @State private var selectedRecommendation: Recommendation?
    @State private var requiredFields: [CategoryField] = []
    @State private var exampleRequests: [String] = []
    @State private var isLoading = false
    @State private var isApplyingBootstrap = false
    @State private var highlightedRecommendationIDs: Set<String> = []
    @State private var lastQuery = ""
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var attachedImages: [UIImage] = []
    @StateObject private var speechController = SpeechInputController()
    @AppStorage("current_user_email") private var currentUserEmail = ""
    @AppStorage("current_user_name") private var currentUserName = ""
    @AppStorage("app_language_code") private var appLanguageCode = "ko"

    private var isEnglish: Bool { !appLanguageCode.lowercased().hasPrefix("ko") }

    private var inputPlaceholder: String {
        if activeModeID == "publish" {
            return isEnglish ? "Speak and AI will post/update for you" : "말하면 AI가 올리거나 수정해요"
        }
        return isEnglish ? "Tell your conditions" : "조건을 말해보세요"
    }

    private var sendLabel: String {
        activeModeID == "publish" ? (isEnglish ? "Post" : "등록") : (isEnglish ? "Send" : "전송")
    }

    private var displayedRecommendations: [Recommendation] {
        recommendations.sorted { lhs, rhs in
            let lAI = highlightedRecommendationIDs.contains(lhs.id)
            let rAI = highlightedRecommendationIDs.contains(rhs.id)
            if lAI != rAI { return lAI && !rAI }
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.id < rhs.id
        }
    }

    private var displayedMessages: [String] {
        Array(messages.suffix(1))
    }

    var body: some View {
        ZStack {
            AppTheme.pageBackground
                .ignoresSafeArea()

            VStack(spacing: 8) {
                if !modes.isEmpty {
                    Picker("모드", selection: $activeModeID) {
                        ForEach(modes) { mode in
                            Text(mode.title).tag(mode.id)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }

                if !promptHint.isEmpty {
                    Text(promptHint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }

                if !requiredFields.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(requiredFields) { field in
                                let satisfied = isFieldSatisfied(field)
                                HStack(spacing: 5) {
                                    Image(systemName: satisfied ? "checkmark.circle.fill" : "circle")
                                        .font(.caption)
                                    Text(field.label)
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(satisfied ? .green : .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(satisfied ? Color.green.opacity(0.12) : Color.secondary.opacity(0.12))
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                if !exampleRequests.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(exampleRequests.prefix(3), id: \.self) { example in
                                Button {
                                    input = example
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles")
                                            .font(.caption)
                                        Text(example)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(AppTheme.tint.opacity(0.12), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(displayedMessages, id: \.self) { msg in
                        Text(msg)
                            .font(.footnote)
                            .lineLimit(3)
                            .truncationMode(.tail)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(bubbleColor(for: msg))
                            )
                    }
                }
                .padding(.horizontal)
                .frame(maxHeight: 74, alignment: .top)

                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("AI가 조건을 분석하고 후보를 찾는 중...")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                } else if !lastQuery.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(AppTheme.tint)
                        Text("AI 추천 기준: \"\(lastQuery)\"")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                }

                List(displayedRecommendations) { item in
                    let isHighlighted = highlightedRecommendationIDs.contains(item.id)
                    let action = actionByRecommendationID[item.id]
                    VStack(alignment: .leading, spacing: 6) {
                        if isHighlighted {
                            Label("AI가 방금 찾은 추천", systemImage: "sparkles")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.tint)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppTheme.tint.opacity(0.12), in: Capsule())
                        }

                        HStack {
                            if isHighlighted {
                                Text("AI")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(AppTheme.tint, in: Capsule())
                            }
                            Text(item.title).font(.headline)
                            Spacer()
                            Text(String(format: "%.0f%%", item.score * 100))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.scorePill)
                                .clipShape(Capsule())
                        }
                        Text(item.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let action {
                            HStack(spacing: 6) {
                                Image(systemName: statusIcon(for: action.status))
                                    .font(.caption2)
                                Text("진행 상태: \(statusLabel(for: action.status))")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(statusColor(for: action.status))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(statusColor(for: action.status).opacity(0.12), in: Capsule())
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(item.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(AppTheme.tagPill)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isHighlighted ? AppTheme.tint.opacity(0.75) : .clear, lineWidth: 1.5)
                            )
                    )
                    .scaleEffect(isHighlighted ? 1.01 : 1.0)
                    .animation(.easeOut(duration: 0.22), value: isHighlighted)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRecommendation = item
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .frame(maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    if !attachedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(attachedImages.enumerated()), id: \.offset) { _, image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 54, height: 54)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(AppTheme.tint.opacity(0.25), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        TextField(inputPlaceholder, text: $input)
                            .textFieldStyle(.roundedBorder)

                        PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: 4, matching: .images) {
                            Image(systemName: attachedImages.isEmpty ? "photo.circle.fill" : "photo.stack.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(attachedImages.isEmpty ? AppTheme.tint : .green)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading)
                        .accessibilityLabel("이미지 첨부")

                        Button {
                            speechController.toggleListening()
                        } label: {
                            Image(systemName: speechController.isListening ? "waveform.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(speechController.isListening ? .red : AppTheme.tint)
                                .scaleEffect(speechController.isListening ? 1.08 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: speechController.isListening)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading)
                        .accessibilityLabel(speechController.isListening ? "음성 입력 중지" : "음성 입력 시작")

                        Button(sendLabel) {
                            Task { await askCategoryAgent() }
                        }
                        .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    }

                    if !speechController.statusMessage.isEmpty {
                        Text(speechController.statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !attachedImages.isEmpty {
                        Text("이미지 \(attachedImages.count)장 첨부됨")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }
        }
        .navigationTitle(category.name)
        .task {
            await bootstrap(mode: nil)
        }
        .onChange(of: activeModeID) { newValue in
            guard !newValue.isEmpty, !isApplyingBootstrap else { return }
            Task { await bootstrap(mode: newValue) }
        }
        .onChange(of: speechController.transcript) { newValue in
            if !newValue.isEmpty {
                input = newValue
            }
        }
        .onChange(of: selectedPhotoItems.count) { _ in
            Task { await loadSelectedPhotos() }
        }
        .onDisappear {
            speechController.stopListening()
        }
        .navigationDestination(
            isPresented: Binding(
                get: { selectedRecommendation != nil },
                set: { isPresented in
                    if !isPresented { selectedRecommendation = nil }
                }
            )
        ) {
            if let recommendation = selectedRecommendation {
                RecommendationDetailView(
                    categoryID: category.id,
                    categoryDomain: category.domain ?? "",
                    categoryName: category.name,
                    recommendation: recommendation,
                    currentAction: actionByRecommendationID[recommendation.id]
                ) { updated in
                    actionByRecommendationID[updated.recommendationID] = updated
                }
            } else {
                EmptyView()
            }
        }
    }

    private func bootstrap(mode: String?) async {
        do {
            async let boot = APIClient.shared.fetchBootstrap(categoryID: category.id, mode: mode)
            async let schema = APIClient.shared.fetchCategorySchema(categoryID: category.id, mode: mode)
            let response = try await boot
            let schemaResponse = try await schema
            let actions = (try? await APIClient.shared.fetchActions(
                categoryID: category.id,
                viewerEmail: currentUserEmail
            )) ?? []
            isApplyingBootstrap = true
            modes = response.modes
            if activeModeID != response.activeMode {
                activeModeID = response.activeMode
            }
            promptHint = response.promptHint
            recommendations = response.recommendations
            actionByRecommendationID = reduceActions(actions)
            requiredFields = schemaResponse.requiredFields
            exampleRequests = schemaResponse.examples
            selectedPhotoItems = []
            attachedImages = []
            highlightedRecommendationIDs.removeAll()
            lastQuery = ""
            messages = ["AI: \(response.welcomeMessage)"]
            isApplyingBootstrap = false
        } catch {
            isApplyingBootstrap = true
            if modes.isEmpty {
                modes = [
                    AgentMode(id: "find", title: "찾기", description: "조건 기반 탐색"),
                    AgentMode(id: "publish", title: "올리기", description: "내 정보 등록")
                ]
            }
            if activeModeID.isEmpty {
                activeModeID = "find"
            }
            let fallbackMode = (mode?.isEmpty == false ? mode! : activeModeID)
            if activeModeID != fallbackMode {
                activeModeID = fallbackMode
            }
            promptHint = localPromptHint(for: activeModeID)
            messages = [localWelcomeMessage(for: activeModeID)]
            recommendations = []
            actionByRecommendationID = [:]
            requiredFields = []
            exampleRequests = []
            selectedPhotoItems = []
            attachedImages = []
            highlightedRecommendationIDs.removeAll()
            lastQuery = ""
            isApplyingBootstrap = false
        }
    }

    private func askCategoryAgent() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        speechController.stopListening()
        speechController.clearTranscript()
        input = ""
        lastQuery = text
        messages = ["나: \(text)"]
        isLoading = true
        defer { isLoading = false }

        do {
            let mode = activeModeID.isEmpty ? "find" : activeModeID
            let previousIDs = Set(recommendations.map(\.id))
            var requestMessage = text
            if mode == "publish" && !attachedImages.isEmpty {
                requestMessage += "\n첨부 이미지: \(attachedImages.count)장"
            }
            let response = try await APIClient.shared.askAgent(
                categoryID: category.id,
                mode: mode,
                message: requestMessage,
                userEmail: currentUserEmail,
                userName: currentUserName.isEmpty ? nil : currentUserName
            )
            messages = ["AI: \(response.assistantMessage)"]
            if mode == "publish" {
                selectedPhotoItems = []
                attachedImages = []
            }
            let currentIDs = response.recommendations.map(\.id)
            let newIDs = Set(currentIDs).subtracting(previousIDs)
            let fallbackHighlights = Set(currentIDs.prefix(3))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                recommendations = response.recommendations
                highlightedRecommendationIDs = newIDs.isEmpty ? fallbackHighlights : newIDs
            }
            await refreshActions()
        } catch {
            messages = ["AI: 서버 연결 실패. /Users/user/AgentA/Sever 에서 ./run_local_ai.sh 실행 후 다시 시도해주세요."]
        }
    }

    private func bubbleColor(for message: String) -> Color {
        if message.hasPrefix("나:") {
            return AppTheme.bubbleUser
        }
        if message.hasPrefix("AI:") {
            return AppTheme.bubbleAI
        }
        return Color(.secondarySystemBackground)
    }

    private func isFieldSatisfied(_ field: CategoryField) -> Bool {
        if field.id == "image" {
            return !attachedImages.isEmpty
        }
        let text = (input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? lastQuery : input).lowercased()
        guard !text.isEmpty else { return false }
        if field.keywords.isEmpty { return false }
        return field.keywords.contains { text.contains($0.lowercased()) }
    }

    private func reduceActions(_ actions: [MatchAction]) -> [String: MatchAction] {
        var out: [String: MatchAction] = [:]
        for action in actions {
            if out[action.recommendationID] == nil {
                out[action.recommendationID] = action
            }
        }
        return out
    }

    private func refreshActions() async {
        let actions = (try? await APIClient.shared.fetchActions(
            categoryID: category.id,
            viewerEmail: currentUserEmail
        )) ?? []
        actionByRecommendationID = reduceActions(actions)
    }

    private func localPromptHint(for mode: String) -> String {
        if mode == "publish" {
            return isEnglish
                ? "Demo mode (offline) · Speak key info and AI will post or update."
                : "서버 연결 없이 데모 모드 · 말하면 AI가 등록/수정해요."
        }
        return isEnglish
            ? "Demo mode (offline) · Enter conditions to preview recommendation flow."
            : "서버 연결 없이 데모 모드 · 조건을 입력하면 추천 흐름을 미리 볼 수 있어요."
    }

    private func localWelcomeMessage(for mode: String) -> String {
        if mode == "publish" {
            if isEnglish {
                switch category.id {
                case "luxury":
                    return "AI: Want to post or update a luxury listing? Tell brand, model, condition, and price."
                case "trade":
                    return "AI: Want to post or update an item? Tell product, condition, price, and location."
                case "dating":
                    return "AI: Want to post or update your dating profile? Tell personality and preferred match."
                case "friend":
                    return "AI: Want to post or update your friend profile? Tell interests and active hours."
                case "soccer", "futsal":
                    return "AI: Want to post or update your team profile? Tell level, location, and time."
                default:
                    return "AI: Want to post or update? Tell core details (title/conditions/price or schedule)."
                }
            }
            switch category.id {
            case "luxury":
                return "AI: 올리고 싶은 명품 가방이 있나요? 브랜드, 모델, 상태, 가격, 인증 정보를 알려주세요."
            case "trade":
                return "AI: 올리고 싶은 판매 물건이 있나요? 상품명, 상태, 가격, 거래방식을 알려주세요."
            case "dating":
                return "AI: 소개팅 프로필을 올려볼까요? 나의 성향, 선호 상대, 활동 지역을 알려주세요."
            case "friend":
                return "AI: 친구 만들기 프로필을 올려볼까요? 관심사, 성향, 활동 시간대를 알려주세요."
            case "soccer", "futsal":
                return "AI: 팀 정보를 올려볼까요? 팀 레벨, 활동 지역, 가능한 시간대를 알려주세요."
            default:
                return "AI: 올리고 싶은 항목이 있나요? 핵심 정보(제목/조건/가격 또는 일정)를 알려주세요."
            }
        }
        return isEnglish
            ? "AI: Tell your conditions and I will show recommendations."
            : "AI: 원하는 조건을 말해주면 추천을 보여줄게요."
    }

    private func statusLabel(for status: String) -> String {
        switch status {
        case "requested": return "요청됨"
        case "accepted": return "수락됨"
        case "rejected": return "거절됨"
        case "confirmed": return "확정됨"
        case "canceled": return "취소됨"
        default: return status
        }
    }

    private func statusIcon(for status: String) -> String {
        switch status {
        case "requested": return "paperplane.circle.fill"
        case "accepted": return "checkmark.circle.fill"
        case "rejected": return "xmark.circle.fill"
        case "confirmed": return "checkmark.seal.fill"
        case "canceled": return "minus.circle.fill"
        default: return "questionmark.circle"
        }
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "requested": return .orange
        case "accepted": return .green
        case "rejected": return .red
        case "confirmed": return .blue
        case "canceled": return .gray
        default: return .secondary
        }
    }

    private func loadSelectedPhotos() async {
        guard !selectedPhotoItems.isEmpty else {
            attachedImages = []
            return
        }
        var images: [UIImage] = []
        for item in selectedPhotoItems.prefix(4) {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                images.append(uiImage)
            }
        }
        attachedImages = images
    }
}

struct RecommendationDetailEditContext {
    let userEmail: String
    let userName: String
    let onSaved: () -> Void
}

struct RecommendationDetailView: View {
    @Environment(\.openURL) private var openURL
    @AppStorage("current_user_email") private var currentUserEmail = ""
    @AppStorage("current_user_name") private var currentUserName = ""
    @AppStorage("app_language_code") private var appLanguageCode = "ko"

    let categoryID: String
    let categoryDomain: String
    let categoryName: String
    let recommendation: Recommendation
    let currentAction: MatchAction?
    let onUpdated: (MatchAction) -> Void
    let editContext: RecommendationDetailEditContext?

    @State private var localRecommendation: Recommendation
    @State private var localAction: MatchAction?
    @State private var note = ""
    @State private var isLoading = false
    @State private var infoMessage = ""
    @State private var editInstruction = ""
    @State private var editInfoMessage = ""
    @State private var isEditSaving = false

    init(
        categoryID: String,
        categoryDomain: String,
        categoryName: String,
        recommendation: Recommendation,
        currentAction: MatchAction?,
        onUpdated: @escaping (MatchAction) -> Void,
        editContext: RecommendationDetailEditContext? = nil
    ) {
        self.categoryID = categoryID
        self.categoryDomain = categoryDomain
        self.categoryName = categoryName
        self.recommendation = recommendation
        self.currentAction = currentAction
        self.onUpdated = onUpdated
        self.editContext = editContext
        _localRecommendation = State(initialValue: recommendation)
        _localAction = State(initialValue: currentAction)
    }

    private var isEnglish: Bool { !appLanguageCode.lowercased().hasPrefix("ko") }
    private func tr(_ ko: String, _ en: String) -> String { isEnglish ? en : ko }
    private var canSendRequest: Bool { !currentUserEmail.isEmpty }
    private var viewerEmail: String {
        !currentUserEmail.isEmpty ? currentUserEmail : (editContext?.userEmail ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                imageSection
                infoSection
                aiEditSection
                variationSection
                actionSection
                contactSection
                historySection
            }
            .padding(16)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .navigationTitle(tr("상세 정보", "Detail"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDetail()
        }
    }

    private var imageSection: some View {
        let images = localRecommendation.imageURLs ?? []
        return Group {
            if images.isEmpty {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(height: 180)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.title2)
                            Text(tr("등록된 이미지 없음", "No image uploaded"))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    )
            } else {
                TabView {
                    ForEach(images, id: \.self) { urlString in
                        AsyncImage(url: URL(string: urlString)) { phase in
                            switch phase {
                            case let .success(image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Color.secondary.opacity(0.12)
                            case .empty:
                                ProgressView()
                            @unknown default:
                                Color.secondary.opacity(0.12)
                            }
                        }
                    }
                }
                .frame(height: 220)
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localRecommendation.title)
                .font(.title3.weight(.bold))
            Text(localRecommendation.subtitle)
                .foregroundStyle(.secondary)
            if let detail = localRecommendation.detail, !detail.isEmpty {
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(5)
            }
            HStack {
                ForEach(localRecommendation.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.tagPill)
                        .clipShape(Capsule())
                }
            }
            HStack(spacing: 6) {
                Text(tr("판매/작성자", "Owner"))
                    .font(.caption.weight(.semibold))
                Text(localRecommendation.ownerName ?? "-")
                    .font(.caption)
                Text("·")
                    .foregroundStyle(.secondary)
                Text(localRecommendation.ownerEmailMasked ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var variationSection: some View {
        if categoryDomain == "market" {
            variationCard(
                title: tr("거래 포인트", "Trade Points"),
                lines: [
                    tr("가격/상태/구성품을 확인하고 요청을 보내세요.", "Check price, condition, and included items before requesting."),
                    tr("요청 수락 후에만 연락처가 공개됩니다.", "Contact is revealed only after acceptance."),
                ]
            )
        } else if categoryDomain == "sport" {
            variationCard(
                title: tr("매치 포인트", "Match Points"),
                lines: [
                    tr("시간대/지역/레벨 조건이 맞는지 확인하세요.", "Verify schedule, location, and level fit."),
                    tr("요청 수락 후 팀 연락 채널이 열립니다.", "Team contact opens after acceptance."),
                ]
            )
        } else {
            variationCard(
                title: tr("매칭 포인트", "Matching Points"),
                lines: [
                    tr("\(categoryName) 카테고리 조건 일치도를 먼저 확인하세요.", "Review how well this candidate fits your \(categoryName) preferences."),
                    tr("상대 수락 이후에만 직접 연락이 가능합니다.", "Direct contact unlocks only after the counterpart accepts."),
                ]
            )
        }
    }

    private func variationCard(title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            ForEach(lines, id: \.self) { line in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .padding(.top, 2)
                    Text(line)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var aiEditSection: some View {
        if let editContext {
            VStack(alignment: .leading, spacing: 10) {
                Text(tr("AI 편집", "AI Edit"))
                    .font(.headline)
                Text(
                    tr(
                        "내가 올린 글입니다. 수정할 내용을 말하듯 입력하면 AI가 같은 글을 업데이트합니다.",
                        "This is your listing. Describe updates naturally and AI will update this exact post."
                    )
                )
                .font(.footnote)
                .foregroundStyle(.secondary)

                TextEditor(text: $editInstruction)
                    .frame(minHeight: 90)
                    .padding(8)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

                HStack {
                    Button {
                        editInstruction = defaultEditInstruction()
                    } label: {
                        Label(tr("예시 채우기", "AutoFill"), systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button {
                        Task { await saveEditByAI(editContext) }
                    } label: {
                        if isEditSaving {
                            ProgressView()
                        } else {
                            Text(tr("AI로 수정 저장", "Save with AI"))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isEditSaving || editInstruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if !editInfoMessage.isEmpty {
                    Text(editInfoMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tr("요청/수락", "Request / Accept"))
                .font(.headline)

            if let action = localAction {
                HStack(spacing: 8) {
                    Image(systemName: statusIcon(action.status))
                    Text("\(tr("현재 상태", "Current status")): \(statusLabel(action.status))")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(statusColor(action.status))

                if !action.allowedActions.isEmpty {
                    HStack {
                        ForEach(action.allowedActions, id: \.self) { command in
                            Button(labelFor(command)) {
                                Task { await transition(command) }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(colorFor(command))
                            .disabled(isLoading || currentUserEmail.isEmpty)
                        }
                    }
                }
            } else if editContext != nil {
                Text(
                    tr(
                        "내 글 상세 보기입니다. 내용 수정은 위의 AI 편집에서 진행하세요.",
                        "This is your listing detail. Use AI Edit above to update content."
                    )
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            } else {
                if canSendRequest {
                    TextField(tr("요청 메모(선택)", "Request note (optional)"), text: $note)
                        .textFieldStyle(.roundedBorder)
                    Button(tr("이 항목 요청하기", "Request this item")) {
                        Task { await request() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                } else {
                    Text(tr("요청 전 이메일 로그인 필요", "Email sign-in required before requesting"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if !infoMessage.isEmpty {
                Text(infoMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tr("연락", "Contact")).font(.headline)
            if let action = localAction, action.contactUnlocked == true {
                Text(tr("상대가 수락해서 연락처가 공개되었습니다.", "Your match accepted. Contact is now unlocked."))
                    .font(.footnote)
                    .foregroundStyle(.green)
                if let name = action.counterpartName {
                    Text("\(tr("상대", "Counterpart")): \(name)")
                        .font(.subheadline)
                }
                if let email = action.counterpartEmail, !email.isEmpty {
                    Button {
                        openURL(URL(string: "mailto:\(email)")!)
                    } label: {
                        Label("\(tr("이메일 보내기", "Send email")): \(email)", systemImage: "envelope")
                    }
                }
                if let phone = action.counterpartPhone, !phone.isEmpty {
                    Button {
                        let digits = phone.filter { $0.isNumber }
                        if let url = URL(string: "sms:\(digits)") {
                            openURL(url)
                        }
                    } label: {
                        Label("\(tr("문자 보내기", "Send SMS")): \(phone)", systemImage: "message")
                    }
                }
            } else {
                Text(tr("수락 전에는 연락처가 비공개입니다.", "Contact is hidden until acceptance."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var historySection: some View {
        if let action = localAction, !action.history.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(tr("진행 이력", "Timeline")).font(.headline)
                ForEach(action.history.indices, id: \.self) { index in
                    let item = action.history[index]
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(statusLabel(item.status)) · \(item.at)")
                            .font(.caption.weight(.semibold))
                        if let note = item.note, !note.isEmpty {
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func loadDetail() async {
        guard !viewerEmail.isEmpty else { return }
        do {
            let detail = try await APIClient.shared.fetchRecommendationDetail(
                categoryID: categoryID,
                recommendationID: recommendation.id,
                viewerEmail: viewerEmail
            )
            localRecommendation = detail.recommendation
            if let action = detail.action {
                localAction = action
                onUpdated(action)
            }
        } catch {
            // fallback 유지
        }
    }

    private func request() async {
        guard !currentUserEmail.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let action = try await APIClient.shared.requestAction(
                categoryID: categoryID,
                recommendation: localRecommendation,
                requesterEmail: currentUserEmail,
                requesterName: currentUserName.isEmpty ? nil : currentUserName,
                note: note.isEmpty ? nil : note
            )
            localAction = action
            onUpdated(action)
            infoMessage = tr("요청이 전송되었습니다.", "Request was sent.")
            note = ""
        } catch {
            infoMessage = tr("요청 생성에 실패했습니다.", "Failed to create request.")
        }
    }

    private func transition(_ command: String) async {
        guard let action = localAction else { return }
        guard !currentUserEmail.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let updated = try await APIClient.shared.transitionAction(
                actionID: action.id,
                command: command,
                actorEmail: currentUserEmail,
                note: note.isEmpty ? nil : note
            )
            localAction = updated
            onUpdated(updated)
            infoMessage = "\(labelFor(command)) \(tr("처리되었습니다.", "completed."))"
            note = ""
        } catch {
            infoMessage = tr("상태 변경에 실패했습니다.", "Failed to update status.")
        }
    }

    private func labelFor(_ command: String) -> String {
        switch command {
        case "accept": return tr("수락", "Accept")
        case "reject": return tr("거절", "Reject")
        case "confirm": return tr("확정", "Confirm")
        case "cancel": return tr("취소", "Cancel")
        default: return command
        }
    }

    private func colorFor(_ command: String) -> Color {
        switch command {
        case "accept", "confirm":
            return .green
        case "reject":
            return .red
        case "cancel":
            return .gray
        default:
            return .blue
        }
    }

    private func statusLabel(_ status: String) -> String {
        switch status {
        case "requested": return tr("요청됨", "Requested")
        case "accepted": return tr("수락됨", "Accepted")
        case "rejected": return tr("거절됨", "Rejected")
        case "confirmed": return tr("확정됨", "Confirmed")
        case "canceled": return tr("취소됨", "Canceled")
        default: return status
        }
    }

    private func statusIcon(_ status: String) -> String {
        switch status {
        case "requested": return "paperplane.circle.fill"
        case "accepted": return "checkmark.circle.fill"
        case "rejected": return "xmark.circle.fill"
        case "confirmed": return "checkmark.seal.fill"
        case "canceled": return "minus.circle.fill"
        default: return "questionmark.circle"
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "requested": return .orange
        case "accepted": return .green
        case "rejected": return .red
        case "confirmed": return .blue
        case "canceled": return .gray
        default: return .secondary
        }
    }

    private func defaultEditInstruction() -> String {
        if isEnglish {
            return "Update this post with clearer constraints and latest availability while keeping the same intent."
        }
        return "이 글을 같은 의도로 유지하면서, 조건/상세 설명/가능 시간(또는 가격)을 더 명확하게 보완해줘."
    }

    private func saveEditByAI(_ context: RecommendationDetailEditContext) async {
        let text = editInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isEditSaving = true
        defer { isEditSaving = false }
        do {
            let message = isEnglish
                ? "Current post summary: \(localRecommendation.subtitle)\nUpdate request: \(text)"
                : "기존 글 요약: \(localRecommendation.subtitle)\n수정 요청: \(text)"
            _ = try await APIClient.shared.askAgent(
                categoryID: categoryID,
                mode: "publish",
                message: message,
                userEmail: context.userEmail,
                userName: context.userName.isEmpty ? nil : context.userName,
                targetRecommendationID: localRecommendation.id
            )
            await loadDetail()
            context.onSaved()
            editInfoMessage = tr("AI가 글을 수정했습니다.", "AI updated your listing.")
            editInstruction = ""
        } catch {
            editInfoMessage = tr("AI 편집에 실패했습니다. 잠시 후 다시 시도해 주세요.", "AI edit failed. Please try again.")
        }
    }
}

private final class SpeechInputController: NSObject, ObservableObject {
    @Published var transcript = ""
    @Published var isListening = false
    @Published var statusMessage = ""

    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    deinit {
        stopListening()
    }

    func clearTranscript() {
        transcript = ""
    }

    func toggleListening() {
        isListening ? stopListening() : requestAndStart()
    }

    func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func requestAndStart() {
        statusMessage = "권한 확인 중..."

        SFSpeechRecognizer.requestAuthorization { [weak self] speechStatus in
            guard let self else { return }
            guard speechStatus == .authorized else {
                DispatchQueue.main.async {
                    self.statusMessage = "설정에서 음성 인식 권한을 허용해주세요."
                }
                return
            }

            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                guard granted else {
                    DispatchQueue.main.async {
                        self.statusMessage = "설정에서 마이크 권한을 허용해주세요."
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.startListeningSession()
                }
            }
        }
    }

    private func startListeningSession() {
        guard !isListening else { return }
        recognitionTask?.cancel()
        recognitionTask = nil

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            recognitionRequest = request

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            isListening = true
            statusMessage = "듣는 중... (마이크 버튼을 다시 누르면 중지)"

            recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
                guard let self else { return }

                if let result {
                    DispatchQueue.main.async {
                        self.transcript = result.bestTranscription.formattedString
                    }
                    if result.isFinal {
                        DispatchQueue.main.async {
                            self.stopListening()
                            self.statusMessage = "음성 입력 완료"
                        }
                        return
                    }
                }

                if error != nil {
                    DispatchQueue.main.async {
                        self.stopListening()
                        self.statusMessage = "음성 인식이 중단되었어요. 다시 시도해주세요."
                    }
                }
            }
        } catch {
            stopListening()
            statusMessage = "음성 입력 시작 실패: \(error.localizedDescription)"
        }
    }
}
