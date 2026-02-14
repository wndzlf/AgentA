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
            GeometryReader { proxy in
                ZStack {
                    AppTheme.pageBackground
                        .ignoresSafeArea()

                    VStack(spacing: 12) {
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.orange.opacity(0.9))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        List(filteredCategories) { category in
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
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                    }
                    .padding(.horizontal)

                    DraggableAgentButton(containerSize: proxy.size) {
                        showQuickAgent = true
                    }
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
