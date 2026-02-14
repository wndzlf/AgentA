import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var query = ""
    @State private var showQuickAgent = false
    @State private var fabBasePosition: CGPoint = .zero
    @State private var fabDragOffset: CGSize = .zero

    private let fabSize: CGFloat = 62
    private let fabMargin: CGFloat = 18

    private var filteredCategories: [Category] {
        guard !query.isEmpty else { return viewModel.categories }
        return viewModel.categories.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.summary.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    VStack(spacing: 12) {
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

                    floatingAgentButton(in: proxy.size)
                }
            }
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

    private func floatingAgentButton(in size: CGSize) -> some View {
        let defaultPoint = defaultFABPosition(in: size)
        let anchor = fabBasePosition == .zero ? defaultPoint : fabBasePosition
        let current = clampedPoint(
            CGPoint(
                x: anchor.x + fabDragOffset.width,
                y: anchor.y + fabDragOffset.height
            ),
            in: size
        )

        return Button {
            showQuickAgent = true
        } label: {
            Image(systemName: "bolt.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: fabSize, height: fabSize)
                .background(Circle().fill(Color.blue))
                .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 3)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .position(current)
        .onAppear {
            if fabBasePosition == .zero {
                fabBasePosition = defaultPoint
            }
        }
        .onChange(of: size) { newSize in
            if fabBasePosition == .zero {
                fabBasePosition = defaultFABPosition(in: newSize)
            } else {
                fabBasePosition = clampedPoint(fabBasePosition, in: newSize)
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    fabDragOffset = value.translation
                }
                .onEnded { value in
                    let start = fabBasePosition == .zero ? defaultPoint : fabBasePosition
                    fabBasePosition = clampedPoint(
                        CGPoint(
                            x: start.x + value.translation.width,
                            y: start.y + value.translation.height
                        ),
                        in: size
                    )
                    fabDragOffset = .zero
                }
        )
        .accessibilityLabel("에이전트에게 바로 물어보기")
    }

    private func defaultFABPosition(in size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width - (fabSize / 2) - fabMargin,
            y: size.height - (fabSize / 2) - fabMargin
        )
    }

    private func clampedPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        let minX = (fabSize / 2) + fabMargin
        let maxX = size.width - (fabSize / 2) - fabMargin
        let minY = (fabSize / 2) + fabMargin
        let maxY = size.height - (fabSize / 2) - fabMargin
        return CGPoint(
            x: min(max(point.x, minX), maxX),
            y: min(max(point.y, minY), maxY)
        )
    }
}
