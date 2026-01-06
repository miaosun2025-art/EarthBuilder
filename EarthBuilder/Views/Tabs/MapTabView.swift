//
//  MapTabView.swift
//  EarthBuilder
//
//  地图页面
//  显示真实地图、用户位置、定位权限请求
//

import SwiftUI
import MapKit

struct MapTabView: View {

    // MARK: - State

    /// 定位管理器
    @StateObject private var locationManager = LocationManager()

    /// 用户位置坐标
    @State private var userLocation: CLLocationCoordinate2D?

    /// 是否已完成首次定位
    @State private var hasLocatedUser = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // 地图视图
            MapViewRepresentable(
                userLocation: $userLocation,
                hasLocatedUser: $hasLocatedUser
            )
            .ignoresSafeArea()

            // 顶部信息栏
            VStack {
                topInfoBar
                Spacer()
            }

            // 右下角定位按钮
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    locationButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }
            }

            // 权限请求提示（未授权时显示）
            if locationManager.isDenied {
                permissionDeniedView
            }
        }
        .onAppear {
            handleOnAppear()
        }
    }

    // MARK: - Subviews

    /// 顶部信息栏
    private var topInfoBar: some View {
        VStack(spacing: 8) {
            // 标题
            Text("末日世界地图")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(ApocalypseTheme.textPrimary)

            // 坐标信息
            if let location = userLocation {
                HStack(spacing: 12) {
                    Image(systemName: "location.fill")
                        .foregroundColor(ApocalypseTheme.primary)
                        .font(.system(size: 14))

                    Text("纬度: \(String(format: "%.4f", location.latitude))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ApocalypseTheme.textPrimary)

                    Text("经度: \(String(format: "%.4f", location.longitude))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ApocalypseTheme.textPrimary)
                }
            } else {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ApocalypseTheme.primary))
                        .scaleEffect(0.8)

                    Text("正在定位...")
                        .font(.system(size: 14))
                        .foregroundColor(ApocalypseTheme.textSecondary)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
            ApocalypseTheme.cardBackground.opacity(0.9)
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 10)
        .padding(.top, 60)
    }

    /// 定位按钮
    private var locationButton: some View {
        Button(action: {
            centerToUserLocation()
        }) {
            ZStack {
                Circle()
                    .fill(ApocalypseTheme.primary)
                    .frame(width: 56, height: 56)
                    .shadow(color: ApocalypseTheme.primary.opacity(0.4), radius: 8)

                Image(systemName: "location.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
        .disabled(userLocation == nil)
        .opacity(userLocation == nil ? 0.5 : 1.0)
    }

    /// 权限被拒绝提示视图
    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            // 警告图标
            ZStack {
                Circle()
                    .fill(ApocalypseTheme.warning.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "location.slash.fill")
                    .font(.system(size: 40))
                    .foregroundColor(ApocalypseTheme.warning)
            }

            // 提示文字
            VStack(spacing: 8) {
                Text("需要定位权限")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(ApocalypseTheme.textPrimary)

                Text("《地球新主》需要获取您的位置\n才能在末日世界中标记您的坐标")
                    .font(.system(size: 14))
                    .foregroundColor(ApocalypseTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // 前往设置按钮
            Button(action: {
                openAppSettings()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                        .font(.system(size: 16))

                    Text("前往设置")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: 160, height: 48)
                .background(
                    LinearGradient(
                        colors: [ApocalypseTheme.primary, ApocalypseTheme.primary.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(24)
                .shadow(color: ApocalypseTheme.primary.opacity(0.3), radius: 8)
            }
        }
        .padding(30)
        .background(
            ApocalypseTheme.cardBackground
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.3), radius: 20)
        .padding(.horizontal, 40)
    }

    // MARK: - Methods

    /// 页面出现时处理
    private func handleOnAppear() {
        print("🗺️ [地图] MapTabView 出现")

        // 检查授权状态
        if locationManager.isAuthorized {
            print("✅ [地图] 已授权，开始定位")
            locationManager.startUpdatingLocation()
        } else if locationManager.authorizationStatus == .notDetermined {
            print("📍 [地图] 未确定授权状态，请求权限")
            locationManager.requestPermission()
        } else {
            print("⚠️ [地图] 授权被拒绝或受限")
        }
    }

    /// 居中到用户位置
    private func centerToUserLocation() {
        print("🎯 [地图] 手动居中到用户位置")
        // 通过重置 hasLocatedUser 触发地图重新居中
        hasLocatedUser = false
    }

    /// 打开应用设置
    private func openAppSettings() {
        print("⚙️ [地图] 打开应用设置")
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview {
    MapTabView()
}
