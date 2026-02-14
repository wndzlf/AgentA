import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var query = ""
    @State private var showQuickAgent = false

    private var filteredCategories: [Category] {
        guard !query.isEmpty else { return viewModel.categories }
        return viewModel.categories.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.summary.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Button {
                    showQuickAgent = true
                } label: {
                    HStack {
                        Image(systemName: "bolt.circle.fill")
                        Text("에이전트에게 바로 물어보기")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding(14)
                    .foregroundStyle(.white)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                List(filteredCategories) { category in
                    NavigationLink(value: category) {
                        HStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .font(.title3)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.name)
                                    .font(.headline)
                                Text(category.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
            .padding(.horizontal)
            .navigationTitle("Agent Match")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "카테고리 검색")
            .navigationDestination(for: Category.self) { category in
                CategoryDetailView(category: category)
            }
            .sheet(isPresented: $showQuickAgent) {
                QuickAgentView()
            }
            .task {
                await viewModel.load()
            }
        }
    }
}
