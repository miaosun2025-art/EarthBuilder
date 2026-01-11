//
//  TerritoryManager.swift
//  EarthBuilder
//
//  领地上传/拉取管理器
//  负责与 Supabase 数据库交互
//

import Foundation
import Combine
import CoreLocation
import Supabase

class TerritoryManager: ObservableObject {

    // MARK: - Singleton

    static let shared = TerritoryManager()

    // MARK: - Published Properties

    @Published var territories: [Territory] = []
    @Published var isLoading = false

    // MARK: - Private Properties

    private let logger = TerritoryLogger.shared

    // MARK: - Initialization

    private init() {
        logger.log("TerritoryManager 初始化", type: .info)
    }

    // MARK: - Path Conversion

    /// 将坐标数组转换为 path JSON 格式
    /// 格式：[{"lat": x, "lon": y}, ...]
    func coordinatesToPathJSON(_ coordinates: [CLLocationCoordinate2D]) -> [[String: Double]] {
        return coordinates.map { coord in
            ["lat": coord.latitude, "lon": coord.longitude]
        }
    }

    /// 将坐标数组转换为 WKT 格式（用于 PostGIS geography 类型）
    /// 注意：WKT 格式是「经度在前，纬度在后」
    /// 多边形必须闭合（首尾相同）
    func coordinatesToWKT(_ coordinates: [CLLocationCoordinate2D]) -> String {
        guard coordinates.count >= 3 else {
            return ""
        }

        var coords = coordinates

        // 确保多边形闭合（首尾相同）
        if let first = coords.first, let last = coords.last {
            if first.latitude != last.latitude || first.longitude != last.longitude {
                coords.append(first)
            }
        }

        // WKT 格式：经度在前，纬度在后
        let pointStrings = coords.map { coord in
            "\(coord.longitude) \(coord.latitude)"
        }

        let polygonString = pointStrings.joined(separator: ", ")
        return "SRID=4326;POLYGON((\(polygonString)))"
    }

    /// 计算边界框
    /// 返回：(minLat, maxLat, minLon, maxLon)
    func calculateBoundingBox(_ coordinates: [CLLocationCoordinate2D]) -> (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double)? {
        guard !coordinates.isEmpty else { return nil }

        let lats = coordinates.map { $0.latitude }
        let lons = coordinates.map { $0.longitude }

        guard let minLat = lats.min(),
              let maxLat = lats.max(),
              let minLon = lons.min(),
              let maxLon = lons.max() else {
            return nil
        }

        return (minLat, maxLat, minLon, maxLon)
    }

    // MARK: - Upload

    /// 上传领地到数据库
    /// - Parameters:
    ///   - coordinates: 领地坐标点数组
    ///   - area: 领地面积（平方米）
    ///   - startTime: 圈地开始时间
    func uploadTerritory(coordinates: [CLLocationCoordinate2D], area: Double, startTime: Date) async throws {
        logger.log("开始上传领地，点数: \(coordinates.count)，面积: \(String(format: "%.2f", area)) m²", type: .info)

        // 获取当前用户
        guard let user = supabase.auth.currentUser else {
            logger.log("上传失败：用户未登录", type: .error)
            throw TerritoryError.notAuthenticated
        }

        // 转换数据格式
        let pathJSON = coordinatesToPathJSON(coordinates)
        let wktPolygon = coordinatesToWKT(coordinates)

        guard let bbox = calculateBoundingBox(coordinates) else {
            logger.log("上传失败：无法计算边界框", type: .error)
            throw TerritoryError.invalidCoordinates
        }

        // 构建上传数据
        let data: [String: AnyJSON] = [
            "user_id": .string(user.id.uuidString),
            "path": .array(pathJSON.map { point in
                .object([
                    "lat": .double(point["lat"]!),
                    "lon": .double(point["lon"]!)
                ])
            }),
            "polygon": .string(wktPolygon),
            "bbox_min_lat": .double(bbox.minLat),
            "bbox_max_lat": .double(bbox.maxLat),
            "bbox_min_lon": .double(bbox.minLon),
            "bbox_max_lon": .double(bbox.maxLon),
            "area": .double(area),
            "point_count": .integer(coordinates.count),
            "started_at": .string(startTime.ISO8601Format()),
            "completed_at": .string(Date().ISO8601Format()),
            "is_active": .bool(true)
        ]

        logger.log("上传数据已准备，正在发送...", type: .info)

        // 执行上传
        try await supabase
            .from("territories")
            .insert(data)
            .execute()

        logger.log("领地上传成功", type: .success)
    }

    // MARK: - Load

    /// 加载所有活跃的领地
    func loadAllTerritories() async throws -> [Territory] {
        logger.log("开始加载所有领地...", type: .info)

        await MainActor.run {
            isLoading = true
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        let response: [Territory] = try await supabase
            .from("territories")
            .select()
            .eq("is_active", value: true)
            .execute()
            .value

        await MainActor.run {
            self.territories = response
        }

        logger.log("加载完成，共 \(response.count) 个领地", type: .success)
        return response
    }

    /// 加载当前用户的领地
    func loadMyTerritories() async throws -> [Territory] {
        guard let user = supabase.auth.currentUser else {
            logger.log("加载失败：用户未登录", type: .error)
            throw TerritoryError.notAuthenticated
        }

        logger.log("加载用户领地...", type: .info)

        let response: [Territory] = try await supabase
            .from("territories")
            .select()
            .eq("user_id", value: user.id.uuidString)
            .eq("is_active", value: true)
            .order("created_at", ascending: false)
            .execute()
            .value

        logger.log("加载完成，共 \(response.count) 个领地", type: .success)
        return response
    }

    // MARK: - Delete

    /// 删除领地
    /// - Parameter territoryId: 领地 ID
    /// - Returns: 是否删除成功
    func deleteTerritory(territoryId: String) async -> Bool {
        logger.log("删除领地: \(territoryId)", type: .info)

        do {
            try await supabase
                .from("territories")
                .delete()
                .eq("id", value: territoryId)
                .execute()

            logger.log("领地删除成功", type: .success)
            return true
        } catch {
            logger.log("领地删除失败: \(error.localizedDescription)", type: .error)
            return false
        }
    }
}

// MARK: - Errors

enum TerritoryError: LocalizedError {
    case notAuthenticated
    case invalidCoordinates
    case uploadFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "用户未登录"
        case .invalidCoordinates:
            return "坐标数据无效"
        case .uploadFailed(let message):
            return "上传失败: \(message)"
        }
    }
}
