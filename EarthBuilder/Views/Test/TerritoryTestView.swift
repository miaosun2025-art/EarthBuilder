//
//  TerritoryTestView.swift
//  EarthBuilder
//
//  圈地功能测试界面
//  实时显示圈地模块的调试日志
//

import SwiftUI

struct TerritoryTestView: View {

    // MARK: - State

    /// 定位管理器（使用单例，监听追踪状态）
    @ObservedObject var locationManager = LocationManager.shared

    /// 日志管理器（监听日志更新）
    @ObservedObject var logger = TerritoryLogger.shared

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景
            ApocalypseTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 状态指示器
                statusIndicator
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                Divider()
                    .background(ApocalypseTheme.textSecondary.opacity(0.2))

                // 日志滚动区域
                logScrollView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // 底部按钮
                actionButtons
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
        }
        .navigationTitle("圈地测试")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Subviews

    /// 状态指示器
    private var statusIndicator: some View {
        HStack(spacing: 12) {
            // 状态点
            Circle()
                .fill(locationManager.isTracking ? Color.green : Color.gray)
                .frame(width: 12, height: 12)

            // 状态文字
            Text(locationManager.isTracking ? "追踪中" : "未追踪")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ApocalypseTheme.textPrimary)

            Spacer()

            // 点数统计
            if !locationManager.pathCoordinates.isEmpty {
                Text("已记录 \(locationManager.pathCoordinates.count) 个点")
                    .font(.system(size: 14))
                    .foregroundColor(ApocalypseTheme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    /// 日志滚动区域
    private var logScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if logger.logs.isEmpty {
                        // 空状态提示
                        Text("暂无日志\n请在地图页面开始圈地追踪")
                            .font(.system(size: 14))
                            .foregroundColor(ApocalypseTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        // 显示日志
                        ForEach(logger.logs) { log in
                            Text(log.displayString)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(logColor(for: log.type))
                                .id(log.id)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            }
            .background(ApocalypseTheme.cardBackground)
            .cornerRadius(12)
            .onChange(of: logger.logText) { oldValue, newValue in
                // 日志更新时自动滚动到底部
                if let lastLog = logger.logs.last {
                    withAnimation {
                        proxy.scrollTo(lastLog.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    /// 底部按钮
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // 清空日志按钮
            Button(action: {
                logger.clear()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))

                    Text("清空日志")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(ApocalypseTheme.danger)
                .cornerRadius(12)
            }
            .disabled(logger.logs.isEmpty)
            .opacity(logger.logs.isEmpty ? 0.5 : 1.0)

            // 导出日志按钮
            ShareLink(item: logger.export()) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))

                    Text("导出日志")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(ApocalypseTheme.primary)
                .cornerRadius(12)
            }
            .disabled(logger.logs.isEmpty)
            .opacity(logger.logs.isEmpty ? 0.5 : 1.0)
        }
    }

    // MARK: - Helper Methods

    /// 根据日志类型返回对应颜色
    /// - Parameter type: 日志类型
    /// - Returns: 对应的颜色
    private func logColor(for type: LogType) -> Color {
        switch type {
        case .info:
            return ApocalypseTheme.textPrimary
        case .success:
            return Color.green
        case .warning:
            return ApocalypseTheme.warning
        case .error:
            return ApocalypseTheme.danger
        }
    }
}

#Preview {
    NavigationStack {
        TerritoryTestView()
    }
}
