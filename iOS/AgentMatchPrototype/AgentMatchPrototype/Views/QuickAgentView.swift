import SwiftUI

struct QuickAgentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var input = ""
    @State private var messages: [String] = ["AI: 무엇을 도와드릴까요? 원하는 카테고리와 조건을 말해보세요."]
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages, id: \.self) { msg in
                            Text(msg)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
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
            let response = try await APIClient.shared.askAgent(categoryID: nil, message: text)
            messages.append("AI: \(response.assistantMessage)")
        } catch {
            messages.append("AI: 서버 연결 실패. Sever 서버를 실행한 뒤 다시 시도해주세요.")
        }
    }
}
