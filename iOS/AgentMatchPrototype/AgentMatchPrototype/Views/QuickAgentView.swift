import SwiftUI

struct QuickAgentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var input = ""
    @State private var messages: [String] = ["AI: 무엇을 도와드릴까요? 원하는 카테고리와 조건을 말해보세요."]
    @State private var routedCategoryName = ""
    @State private var routedMode = "find"
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageBackground
                    .ignoresSafeArea()

                VStack {
                    if !routedCategoryName.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(AppTheme.tint)
                            Text("현재 라우팅: \(routedCategoryName) · \(routedMode == "publish" ? "올리기" : "찾기")")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack {
                        TextField("질문 입력", text: $input)
                            .textFieldStyle(.roundedBorder)
                        Button("전송") {
                            Task { await send() }
                        }
                        .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
            .navigationTitle("빠른 에이전트")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    private func send() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        input = ""
        messages.append("나: \(text)")
        isLoading = true
        defer { isLoading = false }
        do {
            let route = try await APIClient.shared.routeAgent(message: text, limit: 3)
            let selected = route.selected
            let categoryID = selected?.categoryID
            let mode = selected?.suggestedMode ?? "find"
            routedCategoryName = selected?.categoryName ?? "기본"
            routedMode = mode

            if let selected {
                messages.append("시스템: '\(selected.categoryName)' 카테고리로 라우팅 (\(selected.reason))")
            }

            let response = try await APIClient.shared.askAgent(categoryID: categoryID, mode: mode, message: text)
            messages.append("AI: \(response.assistantMessage)")
        } catch {
            messages.append("AI: 서버 연결 실패. /Users/user/AgentA/Sever 에서 ./run_local_ai.sh 실행 후 다시 시도해주세요.")
        }
    }

    private func bubbleColor(for message: String) -> Color {
        message.hasPrefix("나:") ? AppTheme.bubbleUser : AppTheme.bubbleAI
    }
}
