//
//  TerritoryDetailView.swift
//  EarthBuilder
//
//  领地详情页
//  显示领地信息、地图预览、支持删除操作
//

import SwiftUI
import MapKit

struct TerritoryDetailView: View {

    // MARK: - Properties

    /// 领地数据
    let territory: Territory

    /// 删除成功回调
    var onDelete: (() -> Void)?

    /// 用于关闭 sheet
    @Environment(\.dismiss) private var dismiss

    /// 领地管理器
    @ObservedObject private var territoryManager = TerritoryManager.shared

    // MARK: - State

    /// 是否显示删除确认弹窗
    @State private var showDeleteAlert = false

    /// 是否正在删除
    @State private var isDeleting = false

    /// 删除错误信息
    @State private var deleteError: String?

    /// 地图区域
    @State private var mapRegion: MKCoordinateRegion

    // MARK: - Initialization

    init(territory: Territory, onDelete: (() -> Void)? = nil) {
        self.territory = territory
        self.onDelete = onDelete

        // 计算地图区域
        let coordinates = territory.toCoordinates()
        if coordinates.first != nil {
            let lats = coordinates.map { $0.latitude }
            let lons = coordinates.map { $0.longitude }

            let centerLat = (lats.min()! + lats.max()!) / 2
            let centerLon = (lons.min()! + lons.max()!) / 2
            let spanLat = (lats.max()! - lats.min()!) * 1.5
            let spanLon = (lons.max()! - lons.min()!) * 1.5

            _mapRegion = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                span: MKCoordinateSpan(
                    latitudeDelta: max(spanLat, 0.005),
                    longitudeDelta: max(spanLon, 0.005)
                )
            ))
        } else {
            _mapRegion = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 31.2, longitude: 121.4),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 地图预览
                    mapPreview

                    // 领地信息
                    infoSection

                    // 未来功能占位
                    futureFeatures

                    // 删除按钮
                    deleteButton
                }
                .padding()
            }
            .background(ApocalypseTheme.background)
            .navigationTitle(territory.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("确认删除", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    Task {
                        await deleteTerritory()
                    }
                }
            } message: {
                Text("删除后无法恢复，确定要删除这块领地吗？")
            }
        }
    }

    // MARK: - Subviews

    /// 地图预览
    private var mapPreview: some View {
        Map(coordinateRegion: .constant(mapRegion))
        .frame(height: 200)
        .cornerRadius(16)
        .overlay(
            // 领地多边形覆盖层
            TerritoryPolygonOverlay(coordinates: territory.toCoordinates())
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// 领地信息区
    private var infoSection: some View {
        VStack(spacing: 0) {
            InfoRow(icon: "square.dashed", title: "面积", value: territory.formattedArea)
            Divider().padding(.leading, 44)

            if let pointCount = territory.pointCount {
                InfoRow(icon: "mappin.circle", title: "路径点数", value: "\(pointCount) 个")
                Divider().padding(.leading, 44)
            }

            InfoRow(icon: "clock", title: "创建时间", value: territory.formattedDate)
        }
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    /// 未来功能占位
    private var futureFeatures: some View {
        VStack(spacing: 0) {
            FutureFeatureRow(icon: "pencil", title: "重命名领地", subtitle: "敬请期待")
            Divider().padding(.leading, 44)

            FutureFeatureRow(icon: "building.2", title: "建筑系统", subtitle: "敬请期待")
            Divider().padding(.leading, 44)

            FutureFeatureRow(icon: "arrow.left.arrow.right", title: "领地交易", subtitle: "敬请期待")
        }
        .background(ApocalypseTheme.cardBackground)
        .cornerRadius(12)
    }

    /// 删除按钮
    private var deleteButton: some View {
        Button(action: {
            showDeleteAlert = true
        }) {
            HStack {
                if isDeleting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "trash")
                }
                Text(isDeleting ? "删除中..." : "删除领地")
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(ApocalypseTheme.danger)
            .cornerRadius(12)
        }
        .disabled(isDeleting)
        .padding(.top, 20)
    }

    // MARK: - Methods

    /// 删除领地
    private func deleteTerritory() async {
        isDeleting = true
        deleteError = nil

        let success = await territoryManager.deleteTerritory(territoryId: territory.id)

        await MainActor.run {
            isDeleting = false
            if success {
                onDelete?()
                dismiss()
            } else {
                deleteError = "删除失败，请重试"
            }
        }
    }
}

// MARK: - Info Row

/// 信息行组件
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(ApocalypseTheme.primary)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 15))
                .foregroundColor(ApocalypseTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(ApocalypseTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Future Feature Row

/// 未来功能行组件
struct FutureFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(ApocalypseTheme.textSecondary)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 15))
                .foregroundColor(ApocalypseTheme.textSecondary)

            Spacer()

            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(ApocalypseTheme.textSecondary.opacity(0.6))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ApocalypseTheme.textSecondary.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Territory Polygon Overlay

/// 领地多边形覆盖层（简化版，用于预览）
struct TerritoryPolygonOverlay: View {
    let coordinates: [CLLocationCoordinate2D]

    var body: some View {
        GeometryReader { geometry in
            if coordinates.count >= 3 {
                Path { path in
                    // 简化处理：将坐标映射到视图坐标
                    let convertedCoords = CoordinateConverter.wgs84ToGcj02(coordinates)

                    guard let first = convertedCoords.first else { return }

                    // 计算边界
                    let lats = convertedCoords.map { $0.latitude }
                    let lons = convertedCoords.map { $0.longitude }
                    let minLat = lats.min()!
                    let maxLat = lats.max()!
                    let minLon = lons.min()!
                    let maxLon = lons.max()!

                    let latSpan = maxLat - minLat
                    let lonSpan = maxLon - minLon

                    // 映射函数
                    func mapToView(_ coord: CLLocationCoordinate2D) -> CGPoint {
                        let x = (coord.longitude - minLon) / lonSpan * geometry.size.width
                        let y = (maxLat - coord.latitude) / latSpan * geometry.size.height
                        return CGPoint(x: x, y: y)
                    }

                    path.move(to: mapToView(first))
                    for coord in convertedCoords.dropFirst() {
                        path.addLine(to: mapToView(coord))
                    }
                    path.closeSubpath()
                }
                .fill(Color.green.opacity(0.3))
                .overlay(
                    Path { path in
                        let convertedCoords = CoordinateConverter.wgs84ToGcj02(coordinates)

                        guard let first = convertedCoords.first else { return }

                        let lats = convertedCoords.map { $0.latitude }
                        let lons = convertedCoords.map { $0.longitude }
                        let minLat = lats.min()!
                        let maxLat = lats.max()!
                        let minLon = lons.min()!
                        let maxLon = lons.max()!

                        let latSpan = maxLat - minLat
                        let lonSpan = maxLon - minLon

                        func mapToView(_ coord: CLLocationCoordinate2D) -> CGPoint {
                            let x = (coord.longitude - minLon) / lonSpan * geometry.size.width
                            let y = (maxLat - coord.latitude) / latSpan * geometry.size.height
                            return CGPoint(x: x, y: y)
                        }

                        path.move(to: mapToView(first))
                        for coord in convertedCoords.dropFirst() {
                            path.addLine(to: mapToView(coord))
                        }
                        path.closeSubpath()
                    }
                    .stroke(Color.green, lineWidth: 2)
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TerritoryDetailView(
        territory: Territory(
            id: "test-id",
            userId: "user-id",
            name: "测试领地",
            path: [
                ["lat": 31.2, "lon": 121.4],
                ["lat": 31.21, "lon": 121.4],
                ["lat": 31.21, "lon": 121.41],
                ["lat": 31.2, "lon": 121.41]
            ],
            area: 12345,
            pointCount: 15,
            isActive: true,
            completedAt: nil,
            startedAt: nil,
            createdAt: "2025-01-11T10:30:00Z"
        )
    )
}
