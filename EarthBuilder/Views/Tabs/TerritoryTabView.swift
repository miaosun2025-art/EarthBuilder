//
//  TerritoryTabView.swift
//  EarthBuilder
//
//  领地管理页面
//  显示用户的领地列表、统计信息，支持查看详情和删除
//

import SwiftUI

struct TerritoryTabView: View {

    // MARK: - State

    /// 领地管理器
    @ObservedObject private var territoryManager = TerritoryManager.shared

    /// 我的领地列表
    @State private var myTerritories: [Territory] = []

    /// 是否正在加载
    @State private var isLoading = false

    /// 错误信息
    @State private var errorMessage: String?

    /// 选中的领地（用于显示详情）
    @State private var selectedTerritory: Territory?

    // MARK: - Computed Properties

    /// 总面积
    private var totalArea: Double {
        myTerritories.reduce(0) { $0 + $1.area }
    }

    /// 格式化总面积
    private var formattedTotalArea: String {
        if totalArea >= 1_000_000 {
            return String(format: "%.2f km²", totalArea / 1_000_000)
        } else {
            return String(format: "%.0f m²", totalArea)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                ApocalypseTheme.background
                    .ignoresSafeArea()

                if isLoading && myTerritories.isEmpty {
                    // 首次加载中
                    loadingView
                } else if myTerritories.isEmpty {
                    // 空状态
                    emptyStateView
                } else {
                    // 领地列表
                    territoryListView
                }
            }
            .navigationTitle("我的领地")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadMyTerritories()
            }
            .onAppear {
                if myTerritories.isEmpty {
                    Task {
                        await loadMyTerritories()
                    }
                }
            }
            .sheet(item: $selectedTerritory) { territory in
                TerritoryDetailView(
                    territory: territory,
                    onDelete: {
                        // 删除成功后刷新列表
                        Task {
                            await loadMyTerritories()
                        }
                    }
                )
            }
        }
    }

    // MARK: - Subviews

    /// 加载中视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: ApocalypseTheme.primary))
                .scaleEffect(1.5)

            Text("加载中...")
                .font(.system(size: 16))
                .foregroundColor(ApocalypseTheme.textSecondary)
        }
    }

    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "flag.slash")
                .font(.system(size: 60))
                .foregroundColor(ApocalypseTheme.textSecondary)

            Text("暂无领地")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ApocalypseTheme.textPrimary)

            Text("前往地图页面圈地")
                .font(.system(size: 14))
                .foregroundColor(ApocalypseTheme.textSecondary)

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(ApocalypseTheme.danger)
                    .padding(.top, 8)
            }
        }
        .padding()
    }

    /// 领地列表视图
    private var territoryListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 统计卡片
                statsCard

                // 领地列表
                LazyVStack(spacing: 12) {
                    ForEach(myTerritories) { territory in
                        TerritoryCard(territory: territory)
                            .onTapGesture {
                                selectedTerritory = territory
                            }
                    }
                }
            }
            .padding()
        }
    }

    /// 统计卡片
    private var statsCard: some View {
        HStack(spacing: 20) {
            // 领地数量
            VStack(spacing: 4) {
                Text("\(myTerritories.count)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(ApocalypseTheme.primary)

                Text("领地数量")
                    .font(.system(size: 12))
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // 总面积
            VStack(spacing: 4) {
                Text(formattedTotalArea)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(ApocalypseTheme.success)

                Text("总面积")
                    .font(.system(size: 12))
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Methods

    /// 加载我的领地
    private func loadMyTerritories() async {
        isLoading = true
        errorMessage = nil

        do {
            let territories = try await territoryManager.loadMyTerritories()
            await MainActor.run {
                myTerritories = territories
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Territory Card

/// 领地卡片组件
struct TerritoryCard: View {
    let territory: Territory

    var body: some View {
        HStack(spacing: 12) {
            // 领地图标
            ZStack {
                Circle()
                    .fill(ApocalypseTheme.primary.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: "flag.fill")
                    .font(.system(size: 20))
                    .foregroundColor(ApocalypseTheme.primary)
            }

            // 领地信息
            VStack(alignment: .leading, spacing: 4) {
                Text(territory.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ApocalypseTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(territory.formattedArea, systemImage: "square.dashed")
                        .font(.system(size: 12))
                        .foregroundColor(ApocalypseTheme.textSecondary)

                    if let pointCount = territory.pointCount {
                        Label("\(pointCount) 点", systemImage: "mappin.circle")
                            .font(.system(size: 12))
                            .foregroundColor(ApocalypseTheme.textSecondary)
                    }
                }
            }

            Spacer()

            // 时间
            VStack(alignment: .trailing, spacing: 4) {
                Text(territory.formattedDate)
                    .font(.system(size: 11))
                    .foregroundColor(ApocalypseTheme.textSecondary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
        }
        .padding(16)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    TerritoryTabView()
}
