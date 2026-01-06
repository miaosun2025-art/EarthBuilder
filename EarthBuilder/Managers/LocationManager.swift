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

    /// 路径是否闭合（Day16 会用）
    @Published var isPathClosed: Bool = false

    /// 当前位置（私有，供 Timer 使用）
    private var currentLocation: CLLocation?

    /// 采点定时器
    private var pathUpdateTimer: Timer?

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

    override init() {
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

        // 启动 2 秒定时器
        pathUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.recordPathPoint()
        }
    }

    /// 停止路径追踪
    func stopPathTracking() {
        print("🛑 [路径] 停止路径追踪")
        isTracking = false

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
    private func recordPathPoint() {
        guard let location = currentLocation else {
            print("⚠️ [路径] 当前位置为空，跳过记录")
            return
        }

        let coordinate = location.coordinate

        // 检查是否需要记录新点
        if let lastCoordinate = pathCoordinates.last {
            // 计算与上个点的距离
            let lastLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
            let distance = location.distance(from: lastLocation)

            // 距离小于 10 米，不记录
            if distance < 10.0 {
                print("ℹ️ [路径] 距离上个点仅 \(String(format: "%.1f", distance)) 米，跳过记录")
                return
            }
        }

        // 记录新点
        pathCoordinates.append(coordinate)
        pathUpdateVersion += 1

        print("📍 [路径] 记录新点 (\(coordinate.latitude), \(coordinate.longitude))，当前共 \(pathCoordinates.count) 个点")
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
