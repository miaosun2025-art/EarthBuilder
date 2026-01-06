//
//  LocationManager.swift
//  EarthBuilder
//
//  GPS 定位管理器
//  负责请求定位权限、获取用户位置、处理定位错误
//

import Foundation
import CoreLocation
import Combine

/// GPS 定位管理器
/// 负责管理应用的定位功能，包括权限请求、位置更新等
class LocationManager: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = LocationManager()

    // MARK: - Properties

    /// CoreLocation 定位管理器
    private let locationManager = CLLocationManager()

    /// 用户当前位置坐标
    @Published var userLocation: CLLocationCoordinate2D?

    /// 定位授权状态
    @Published var authorizationStatus: CLAuthorizationStatus

    /// 定位错误信息
    @Published var locationError: String?

    // MARK: - Path Tracking Properties

    /// 是否正在追踪路径
    @Published var isTracking: Bool = false

    /// 路径坐标数组（存储原始 WGS-84 坐标）
    @Published var pathCoordinates: [CLLocationCoordinate2D] = []

    /// 路径更新版本号（用于触发 SwiftUI 更新）
    @Published var pathUpdateVersion: Int = 0

    /// 路径是否闭合
    @Published var isPathClosed: Bool = false

    /// 当前位置（私有，供 Timer 使用）
    private var currentLocation: CLLocation?

    /// 采点定时器
    private var pathUpdateTimer: Timer?

    // MARK: - Speed Detection Properties

    /// 速度警告信息
    @Published var speedWarning: String?

    /// 是否超速
    @Published var isOverSpeed: Bool = false

    /// 上次位置的时间戳（用于计算速度）
    private var lastLocationTimestamp: Date?

    // MARK: - Constants

    /// 闭环距离阈值（米）
    private let closureDistanceThreshold: Double = 30.0

    /// 最少路径点数
    private let minimumPathPoints: Int = 10

    /// 最小距离阈值（米）- 两点之间最小距离
    private let minimumDistanceForNewPoint: Double = 10.0

    // MARK: - Computed Properties

    /// 是否已授权定位
    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }

    /// 是否拒绝授权
    var isDenied: Bool {
        authorizationStatus == .denied
    }

    // MARK: - Initialization

    private override init() {
        // 初始化授权状态
        self.authorizationStatus = locationManager.authorizationStatus

        super.init()

        // 配置定位管理器
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // 最高精度
        locationManager.distanceFilter = 10 // 移动10米才更新位置

        print("📍 [定位] LocationManager 初始化完成")
    }

    // MARK: - Public Methods

    /// 请求定位权限
    func requestPermission() {
        print("📍 [定位] 请求定位权限")
        locationManager.requestWhenInUseAuthorization()
    }

    /// 开始更新位置
    func startUpdatingLocation() {
        guard isAuthorized else {
            print("⚠️ [定位] 未授权，无法开始定位")
            locationError = "未授权定位权限"
            return
        }

        print("📍 [定位] 开始更新位置")
        locationManager.startUpdatingLocation()
    }

    /// 停止更新位置
    func stopUpdatingLocation() {
        print("📍 [定位] 停止更新位置")
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Path Tracking Methods

    /// 开始路径追踪
    func startPathTracking() {
        guard isAuthorized else {
            print("⚠️ [路径] 未授权，无法开始追踪")
            return
        }

        print("🚩 [路径] 开始路径追踪")
        isTracking = true

        // 记录日志
        TerritoryLogger.shared.log("开始圈地追踪", type: .info)

        // 启动 2 秒定时器
        pathUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.recordPathPoint()
        }
    }

    /// 停止路径追踪
    func stopPathTracking() {
        print("🛑 [路径] 停止路径追踪")
        isTracking = false

        // 记录日志
        TerritoryLogger.shared.log("停止追踪，共 \(pathCoordinates.count) 个点", type: .info)

        // 停止定时器
        pathUpdateTimer?.invalidate()
        pathUpdateTimer = nil
    }

    /// 清除路径
    func clearPath() {
        print("🗑️ [路径] 清除路径")
        pathCoordinates.removeAll()
        pathUpdateVersion += 1
        isPathClosed = false
    }

    /// 记录路径点（定时器回调）
    /// ⚠️ 关键：先检查距离，再检查速度！顺序不能反！
    private func recordPathPoint() {
        guard isTracking, let location = currentLocation else {
            print("⚠️ [路径] 当前位置为空或未在追踪，跳过记录")
            return
        }

        let coordinate = location.coordinate

        // 步骤1：先检查距离（过滤 GPS 漂移，距离不够就直接返回）
        if let lastCoordinate = pathCoordinates.last {
            let lastLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
            let distance = location.distance(from: lastLocation)

            // 距离小于阈值，不记录
            guard distance >= minimumDistanceForNewPoint else {
                print("ℹ️ [路径] 距离上个点仅 \(String(format: "%.1f", distance)) 米，跳过记录")
                return
            }
        }

        // 步骤2：再检查速度（只对真实移动进行检测）
        guard validateMovementSpeed(newLocation: location) else {
            print("⚠️ [路径] 速度检测未通过，不记录此点")
            return
        }

        // 步骤3：记录新点
        pathCoordinates.append(coordinate)
        pathUpdateVersion += 1

        let count = pathCoordinates.count
        print("📍 [路径] 记录新点 (\(coordinate.latitude), \(coordinate.longitude))，当前共 \(count) 个点")

        // 记录日志
        if count > 1, let lastCoordinate = pathCoordinates.dropLast().last {
            let lastLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
            let distance = location.distance(from: lastLocation)
            TerritoryLogger.shared.log("记录第 \(count) 个点，距上点 \(String(format: "%.1f", distance))m", type: .info)
        } else {
            TerritoryLogger.shared.log("记录第 \(count) 个点（起点）", type: .info)
        }

        // 步骤4：检测闭环
        checkPathClosure()
    }

    // MARK: - Closure Detection

    /// 检测路径是否闭环
    private func checkPathClosure() {
        // 已经闭环了，不再检测
        guard !isPathClosed else {
            return
        }

        // 检查点数是否足够
        guard pathCoordinates.count >= minimumPathPoints else {
            print("ℹ️ [闭环] 点数不足（当前 \(pathCoordinates.count) 个，需要至少 \(minimumPathPoints) 个）")
            return
        }

        // 获取起点和当前位置
        guard let startCoordinate = pathCoordinates.first,
              let currentCoordinate = pathCoordinates.last else {
            return
        }

        // 计算当前位置到起点的距离
        let startLocation = CLLocation(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude)
        let currentLocation = CLLocation(latitude: currentCoordinate.latitude, longitude: currentCoordinate.longitude)
        let distance = currentLocation.distance(from: startLocation)

        print("🔍 [闭环] 当前位置距起点 \(String(format: "%.1f", distance)) 米")

        // 记录距离日志（只有点数 ≥10 且未闭环时才记录）
        TerritoryLogger.shared.log("距起点 \(String(format: "%.1f", distance))m (需≤30m)", type: .info)

        // 判断是否闭环
        if distance <= closureDistanceThreshold {
            isPathClosed = true
            pathUpdateVersion += 1
            print("✅ [闭环] 检测成功！距离起点 \(String(format: "%.1f", distance)) 米 ≤ \(closureDistanceThreshold) 米")

            // 记录闭环成功日志（只显示一次）
            TerritoryLogger.shared.log("闭环成功！距起点 \(String(format: "%.1f", distance))m", type: .success)
        } else {
            print("ℹ️ [闭环] 未闭环，距离起点 \(String(format: "%.1f", distance)) 米 > \(closureDistanceThreshold) 米")
        }
    }

    // MARK: - Speed Detection

    /// 验证移动速度
    /// - Parameter newLocation: 新位置
    /// - Returns: true 表示可以记录该点，false 表示不记录
    private func validateMovementSpeed(newLocation: CLLocation) -> Bool {
        // 如果是第一个点，直接记录
        guard let lastTimestamp = lastLocationTimestamp,
              let lastCoordinate = pathCoordinates.last else {
            lastLocationTimestamp = Date()
            return true
        }

        // 计算时间差（秒）
        let currentTime = Date()
        let timeDiff = currentTime.timeIntervalSince(lastTimestamp)

        // 计算距离（米）
        let lastLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
        let distance = newLocation.distance(from: lastLocation)

        // 计算速度（km/h）
        let speed = (distance / timeDiff) * 3.6

        print("🚗 [速度] 距离: \(String(format: "%.1f", distance))米, 时间: \(String(format: "%.1f", timeDiff))秒, 速度: \(String(format: "%.1f", speed)) km/h")

        // 更新时间戳
        lastLocationTimestamp = currentTime

        // 速度判断
        if speed > 30.0 {
            // 严重超速，停止追踪
            DispatchQueue.main.async {
                self.speedWarning = "速度过快！(\(String(format: "%.1f", speed)) km/h) 已自动停止追踪"
                self.isOverSpeed = true
            }
            print("🚨 [速度] 严重超速 \(String(format: "%.1f", speed)) km/h > 30 km/h，停止追踪")

            // 记录错误日志
            TerritoryLogger.shared.log("超速 \(String(format: "%.1f", speed)) km/h，已停止追踪", type: .error)

            stopPathTracking()
            return false
        } else if speed > 15.0 {
            // 超速警告，但继续记录
            DispatchQueue.main.async {
                self.speedWarning = "移动速度过快！(\(String(format: "%.1f", speed)) km/h)"
                self.isOverSpeed = true
            }
            print("⚠️ [速度] 超速警告 \(String(format: "%.1f", speed)) km/h > 15 km/h，继续记录")

            // 记录警告日志
            TerritoryLogger.shared.log("速度较快 \(String(format: "%.1f", speed)) km/h", type: .warning)

            return true
        } else {
            // 正常速度（不记录日志，避免日志过多）
            DispatchQueue.main.async {
                self.speedWarning = nil
                self.isOverSpeed = false
            }
            return true
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    /// 授权状态改变时调用
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        print("📍 [定位] 授权状态改变: \(statusString(newStatus))")

        // 更新授权状态
        authorizationStatus = newStatus

        // 如果已授权，自动开始定位
        if isAuthorized {
            startUpdatingLocation()
        }
    }

    /// 位置更新时调用
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let coordinate = location.coordinate
        print("📍 [定位] 位置更新: 纬度 \(coordinate.latitude), 经度 \(coordinate.longitude)")

        // 更新当前位置（供 Timer 使用）
        self.currentLocation = location

        // 更新用户位置
        DispatchQueue.main.async {
            self.userLocation = coordinate
            self.locationError = nil
        }
    }

    /// 定位失败时调用
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ [定位] 定位失败: \(error.localizedDescription)")

        DispatchQueue.main.async {
            self.locationError = "定位失败: \(error.localizedDescription)"
        }
    }

    // MARK: - Helper Methods

    /// 将授权状态转换为字符串（用于日志）
    private func statusString(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "未确定"
        case .restricted:
            return "受限制"
        case .denied:
            return "已拒绝"
        case .authorizedAlways:
            return "始终允许"
        case .authorizedWhenInUse:
            return "使用时允许"
        @unknown default:
            return "未知状态"
        }
    }
}
