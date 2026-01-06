//
//  MapViewRepresentable.swift
//  EarthBuilder
//
//  MKMapView 的 SwiftUI 包装器
//  负责显示地图、应用末世滤镜、处理用户位置更新
//

import SwiftUI
import MapKit

/// MKMapView 的 SwiftUI 包装器
/// 将 UIKit 的 MKMapView 转换为 SwiftUI 可用的视图
struct MapViewRepresentable: UIViewRepresentable {

    // MARK: - Bindings

    /// 用户位置（绑定到外部状态）
    @Binding var userLocation: CLLocationCoordinate2D?

    /// 是否已完成首次定位（防止重复居中）
    @Binding var hasLocatedUser: Bool

    /// 追踪路径坐标数组（绑定到外部状态）
    @Binding var trackingPath: [CLLocationCoordinate2D]

    /// 路径更新版本号
    let pathUpdateVersion: Int

    /// 是否正在追踪
    let isTracking: Bool

    // MARK: - UIViewRepresentable

    /// 创建并配置 MKMapView
    func makeUIView(context: Context) -> MKMapView {
        print("🗺️ [地图] 创建 MKMapView")

        let mapView = MKMapView()

        // 基础配置
        mapView.mapType = .hybrid // 卫星图 + 道路标签（末世废土风格）
        mapView.pointOfInterestFilter = .excludingAll // 隐藏所有 POI 标签（商店、餐厅等）
        mapView.showsBuildings = false // 隐藏 3D 建筑
        mapView.showsUserLocation = true // 显示用户位置蓝点（⚠️ 关键！）
        mapView.isZoomEnabled = true // 允许双指缩放
        mapView.isScrollEnabled = true // 允许单指拖动
        mapView.isRotateEnabled = true // 允许旋转
        mapView.isPitchEnabled = false // 禁用倾斜（保持平面视图）

        // 设置代理（⚠️ 关键！用于接收位置更新回调）
        mapView.delegate = context.coordinator

        // 应用末世滤镜
        applyApocalypseFilter(to: mapView)

        print("✅ [地图] MKMapView 配置完成")

        return mapView
    }

    /// 更新视图
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 更新追踪路径
        context.coordinator.updateTrackingPath(on: uiView, path: trackingPath, version: pathUpdateVersion)
    }

    /// 创建协调器（Coordinator）
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Helper Methods

    /// 应用末世滤镜效果
    /// - Parameter mapView: 要应用滤镜的地图视图
    private func applyApocalypseFilter(to mapView: MKMapView) {
        print("🎨 [地图] 应用末世滤镜")

        // 色调控制：降低饱和度和亮度
        let colorControls = CIFilter(name: "CIColorControls")
        colorControls?.setValue(-0.15, forKey: kCIInputBrightnessKey) // 稍微变暗
        colorControls?.setValue(0.5, forKey: kCIInputSaturationKey) // 降低饱和度（50%）

        // 棕褐色调：废土的泛黄效果
        let sepiaFilter = CIFilter(name: "CISepiaTone")
        sepiaFilter?.setValue(0.65, forKey: kCIInputIntensityKey) // 棕褐色强度 65%

        // 应用到地图图层
        if let colorControls = colorControls, let sepiaFilter = sepiaFilter {
            mapView.layer.filters = [colorControls, sepiaFilter]
            print("✅ [地图] 末世滤镜应用成功")
        } else {
            print("⚠️ [地图] 滤镜创建失败")
        }
    }

    // MARK: - Coordinator

    /// 协调器：处理 MKMapView 的代理回调
    class Coordinator: NSObject, MKMapViewDelegate {

        // MARK: - Properties

        /// 父视图引用
        var parent: MapViewRepresentable

        /// 首次居中标志（防止重复自动居中）
        private var hasInitialCentered = false

        /// 上次更新的路径版本号
        private var lastPathVersion: Int = -1

        // MARK: - Initialization

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
            super.init()
            print("🎯 [地图] Coordinator 初始化")
        }

        // MARK: - MKMapViewDelegate

        /// ⭐ 关键方法：用户位置更新时调用
        /// 负责自动居中地图到用户位置（仅首次）
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            // 获取位置
            guard let location = userLocation.location else {
                print("⚠️ [地图] 位置信息无效")
                return
            }

            let coordinate = location.coordinate
            print("📍 [地图] 用户位置更新: 纬度 \(coordinate.latitude), 经度 \(coordinate.longitude)")

            // 更新绑定的位置
            DispatchQueue.main.async {
                self.parent.userLocation = coordinate
            }

            // 检查是否已完成首次居中
            guard !hasInitialCentered else {
                print("ℹ️ [地图] 已完成首次居中，跳过自动居中")
                return
            }

            print("🎯 [地图] 执行首次自动居中")

            // 创建居中区域（约 1 公里范围）
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1000, // 纬度方向 1000 米
                longitudinalMeters: 1000  // 经度方向 1000 米
            )

            // 平滑居中地图（⚠️ animated: true 实现平滑过渡）
            mapView.setRegion(region, animated: true)

            // 标记已完成首次居中
            hasInitialCentered = true

            // 更新外部状态
            DispatchQueue.main.async {
                self.parent.hasLocatedUser = true
            }

            print("✅ [地图] 首次居中完成")
        }

        /// 地图区域改变时调用（用户拖动或自动居中）
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            let center = mapView.region.center
            print("🗺️ [地图] 地图区域改变: 中心点 (\(center.latitude), \(center.longitude))")
        }

        /// 地图加载完成时调用
        func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
            print("✅ [地图] 地图加载完成")
        }

        // MARK: - Path Tracking

        /// 更新追踪路径
        /// - Parameters:
        ///   - mapView: 地图视图
        ///   - path: 路径坐标数组
        ///   - version: 路径版本号
        func updateTrackingPath(on mapView: MKMapView, path: [CLLocationCoordinate2D], version: Int) {
            // 检查版本号是否改变
            guard version != lastPathVersion else {
                return
            }

            print("🛤️ [地图] 更新追踪路径，版本 \(version)，共 \(path.count) 个点")

            // 移除所有旧的 overlay
            mapView.removeOverlays(mapView.overlays)

            // 如果路径为空，直接返回
            guard path.count >= 2 else {
                print("ℹ️ [地图] 路径点数不足 2 个，跳过绘制")
                lastPathVersion = version
                return
            }

            // ⚠️ 关键：转换坐标（WGS-84 → GCJ-02）
            let convertedPath = CoordinateConverter.wgs84ToGcj02(path)

            // 创建 polyline
            let polyline = MKPolyline(coordinates: convertedPath, count: convertedPath.count)

            // 添加到地图
            mapView.addOverlay(polyline)

            // 更新版本号
            lastPathVersion = version

            print("✅ [地图] 轨迹绘制完成")
        }

        /// ⭐ 关键方法：为 overlay 提供渲染器（否则轨迹不显示！）
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.cyan // 青色轨迹
                renderer.lineWidth = 5.0 // 线宽 5pt
                renderer.lineCap = .round // 圆头线
                print("🎨 [地图] 创建轨迹渲染器")
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
