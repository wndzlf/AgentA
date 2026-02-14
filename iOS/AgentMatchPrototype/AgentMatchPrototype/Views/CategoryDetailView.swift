import SwiftUI

struct CategoryDetailView: View {
    let category: Category

    @State private var promptHint = ""
    @State private var input = ""
    @State private var messages: [String] = []
    @State private var recommendations: [Recommendation] = []
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 10) {
            if !promptHint.isEmpty {
                Text(promptHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(messages, id: \.self) { msg in
                        Text(msg)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal)
            }

            List(recommendations) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.title).font(.headline)
                        Spacer()
                        Text(String(format: "%.0f%%", item.score * 100))
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.15))
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
                                    .background(Color.gray.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            .listStyle(.plain)

            HStack {
                TextField("조건을 말해보세요", text: $input)
                    .textFieldStyle(.roundedBorder)
                Button("전송") {
                    Task { await askCategoryAgent() }
                }
                .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .padding()
        }
        .navigationTitle(category.name)
        .task {
            await bootstrap()
        }
    }

    private func bootstrap() async {
        do {
            let response = try await APIClient.shared.fetchBootstrap(categoryID: category.id)
            promptHint = response.promptHint
            recommendations = response.recommendations
            messages = ["AI: \(response.welcomeMessage)"]
        } catch {
            promptHint = "서버 연결 없이 데모 모드"
            messages = ["AI: 원하는 조건을 말해주면 추천을 보여줄게요."]
            recommendations = []
        }
    }

    private func askCategoryAgent() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        input = ""
        messages.append("나: \(text)")
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await APIClient.shared.askAgent(categoryID: category.id, message: text)
            messages.append("AI: \(response.assistantMessage)")
            recommendations = response.recommendations
        } catch {
            messages.append("AI: 서버 연결 실패. /Users/user/AgentA/Sever 에서 ./run_local_ai.sh 실행 후 다시 시도해주세요.")
        }
    }
}
