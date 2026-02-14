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
    @State private var requiredFields: [CategoryField] = []
    @State private var exampleRequests: [String] = []
    @State private var isLoading = false
    @State private var isApplyingBootstrap = false
    @State private var highlightedRecommendationIDs: Set<String> = []
    @State private var lastQuery = ""
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var attachedImages: [UIImage] = []
    @StateObject private var speechController = SpeechInputController()

    private var inputPlaceholder: String {
        activeModeID == "publish" ? "등록할 내용을 입력하세요" : "조건을 말해보세요"
    }

    private var sendLabel: String {
        activeModeID == "publish" ? "등록" : "전송"
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

    var body: some View {
        ZStack {
            AppTheme.pageBackground
                .ignoresSafeArea()

            VStack(spacing: 10) {
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
                                .overlay(alignment: .topTrailing) {
                                    if !satisfied {
                                        Text(field.hint)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.ultraThinMaterial, in: Capsule())
                                            .offset(x: 5, y: -6)
                                    }
                                }
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

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(messages, id: \.self) { msg in
                            Text(msg)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(bubbleColor(for: msg))
                                )
                        }
                    }
                    .padding(.horizontal)
                }

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
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

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
    }

    private func bootstrap(mode: String?) async {
        do {
            async let boot = APIClient.shared.fetchBootstrap(categoryID: category.id, mode: mode)
            async let schema = APIClient.shared.fetchCategorySchema(categoryID: category.id, mode: mode)
            let response = try await boot
            let schemaResponse = try await schema
            isApplyingBootstrap = true
            modes = response.modes
            if activeModeID != response.activeMode {
                activeModeID = response.activeMode
            }
            promptHint = response.promptHint
            recommendations = response.recommendations
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
            promptHint = "서버 연결 없이 데모 모드"
            messages = ["AI: 원하는 조건을 말해주면 추천을 보여줄게요."]
            recommendations = []
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
        messages.append("나: \(text)")
        isLoading = true
        defer { isLoading = false }

        do {
            let mode = activeModeID.isEmpty ? "find" : activeModeID
            let previousIDs = Set(recommendations.map(\.id))
            var requestMessage = text
            if mode == "publish" && !attachedImages.isEmpty {
                requestMessage += "\n첨부 이미지: \(attachedImages.count)장"
            }
            let response = try await APIClient.shared.askAgent(categoryID: category.id, mode: mode, message: requestMessage)
            if let action = response.actionResult, !action.isEmpty {
                messages.append("시스템: \(action)")
            }
            messages.append("AI: \(response.assistantMessage)")
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
        } catch {
            messages.append("AI: 서버 연결 실패. /Users/user/AgentA/Sever 에서 ./run_local_ai.sh 실행 후 다시 시도해주세요.")
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
