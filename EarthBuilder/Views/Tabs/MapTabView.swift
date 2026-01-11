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

    /// 定位管理器（使用单例）
    @ObservedObject private var locationManager = LocationManager.shared

    /// 领地管理器（使用单例）
    @ObservedObject private var territoryManager = TerritoryManager.shared

    /// 认证管理器（获取当前用户 ID）
    @EnvironmentObject private var authManager: AuthManager

    /// 用户位置坐标
    @State private var userLocation: CLLocationCoordinate2D?

    /// 已加载的领地列表
    @State private var territories: [Territory] = []

    /// 是否已完成首次定位
    @State private var hasLocatedUser = false

    /// 是否显示验证结果横幅
    @State private var showValidationBanner = false

    /// 是否正在上传
    @State private var isUploading = false

    /// 上传结果提示
    @State private var uploadResultMessage: String?

    /// 是否显示上传结果
    @State private var showUploadResult = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // 地图视图
            MapViewRepresentable(
                userLocation: $userLocation,
                hasLocatedUser: $hasLocatedUser,
                trackingPath: $locationManager.pathCoordinates,
                pathUpdateVersion: locationManager.pathUpdateVersion,
                isTracking: locationManager.isTracking,
                isPathClosed: locationManager.isPathClosed,
                territories: territories,
                currentUserId: authManager.currentUser?.id.uuidString
            )
            .ignoresSafeArea()

            // 顶部信息栏
            VStack {
                topInfoBar

                // 速度警告横幅
                if let warning = locationManager.speedWarning {
                    speedWarningBanner(warning: warning)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 验证结果横幅（闭环后显示成功/失败）
                if showValidationBanner {
                    validationResultBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 上传结果提示
                if showUploadResult, let message = uploadResultMessage {
                    uploadResultBanner(message: message)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // 确认登记按钮区域（验证通过时显示）
                if locationManager.isPathClosed {
                    territoryActionButtons
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }

                Spacer()
            }

            // 右下角按钮组
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        // 圈地按钮
                        trackingButton

                        // 定位按钮
                        locationButton
                    }
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
            // 加载所有领地
            Task {
                await loadTerritories()
            }
        }
        .onChange(of: locationManager.speedWarning) { oldValue, newValue in
            // 速度警告出现时，3 秒后自动隐藏
            if newValue != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if locationManager.speedWarning == newValue {
                        locationManager.speedWarning = nil
                    }
                }
            }
        }
        .onChange(of: locationManager.isPathClosed) { oldValue, newValue in
            // 监听闭环状态，闭环后根据验证结果显示横幅
            if newValue {
                // 闭环后延迟一点点，等待验证结果
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        showValidationBanner = true
                    }
                    // 3 秒后自动隐藏
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showValidationBanner = false
                        }
                    }
                }
            }
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

    /// 圈地按钮
    private var trackingButton: some View {
        Button(action: {
            toggleTracking()
        }) {
            HStack(spacing: 8) {
                Image(systemName: locationManager.isTracking ? "stop.fill" : "flag.fill")
                    .font(.system(size: 16))

                Text(locationManager.isTracking ? "停止圈地" : "开始圈地")
                    .font(.system(size: 16, weight: .semibold))

                if locationManager.isTracking && !locationManager.pathCoordinates.isEmpty {
                    Text("(\(locationManager.pathCoordinates.count))")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(
                        locationManager.isTracking
                            ? ApocalypseTheme.danger
                            : ApocalypseTheme.primary
                    )
            )
            .shadow(
                color: (locationManager.isTracking ? ApocalypseTheme.danger : ApocalypseTheme.primary).opacity(0.4),
                radius: 8
            )
        }
        .disabled(userLocation == nil)
        .opacity(userLocation == nil ? 0.5 : 1.0)
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

    /// 速度警告横幅
    private func speedWarningBanner(warning: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)

            Text(warning)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            locationManager.isTracking
                ? ApocalypseTheme.warning // 还在追踪：黄色警告
                : ApocalypseTheme.danger   // 已停止追踪：红色严重
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 8)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    /// 验证结果横幅（根据验证结果显示成功或失败）
    private var validationResultBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: locationManager.territoryValidationPassed
                  ? "checkmark.circle.fill"
                  : "xmark.circle.fill")
                .font(.body)

            if locationManager.territoryValidationPassed {
                Text("圈地成功！领地面积: \(String(format: "%.0f", locationManager.calculatedArea))m²")
                    .font(.subheadline)
                    .fontWeight(.medium)
            } else {
                Text(locationManager.territoryValidationError ?? "验证失败")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(locationManager.territoryValidationPassed ? Color.green : Color.red)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 8)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    /// 领地操作按钮（确认登记 / 取消）
    private var territoryActionButtons: some View {
        HStack(spacing: 16) {
            // 取消按钮
            Button(action: {
                withAnimation {
                    locationManager.stopPathTracking()
                    showValidationBanner = false
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                    Text("取消")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.8))
                .cornerRadius(10)
            }

            // 确认登记按钮（仅验证通过时可用）
            if locationManager.territoryValidationPassed {
                Button(action: {
                    Task {
                        await uploadCurrentTerritory()
                    }
                }) {
                    HStack(spacing: 6) {
                        if isUploading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Text(isUploading ? "登记中..." : "确认登记")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(10)
                }
                .disabled(isUploading)
            }
        }
        .padding(.horizontal, 20)
    }

    /// 上传结果横幅
    private func uploadResultBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: message.contains("成功") ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.body)

            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(message.contains("成功") ? Color.green : Color.red)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 8)
        .padding(.horizontal, 20)
        .padding(.top, 8)
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

    /// 切换追踪状态
    private func toggleTracking() {
        if locationManager.isTracking {
            print("🛑 [地图] 停止圈地")
            locationManager.stopPathTracking()
        } else {
            print("🚩 [地图] 开始圈地")
            locationManager.startPathTracking()
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

    /// 上传当前领地
    private func uploadCurrentTerritory() async {
        // 再次检查验证状态
        guard locationManager.territoryValidationPassed else {
            showUploadError("领地验证未通过，无法上传")
            return
        }

        // 检查是否有数据
        guard !locationManager.pathCoordinates.isEmpty else {
            showUploadError("没有可上传的领地数据")
            return
        }

        // 开始上传
        await MainActor.run {
            isUploading = true
        }

        do {
            try await territoryManager.uploadTerritory(
                coordinates: locationManager.pathCoordinates,
                area: locationManager.calculatedArea,
                startTime: locationManager.trackingStartTime ?? Date()
            )

            // 上传成功
            await MainActor.run {
                isUploading = false
                showValidationBanner = false

                // 显示成功提示
                uploadResultMessage = "领地登记成功！面积: \(Int(locationManager.calculatedArea))m²"
                withAnimation {
                    showUploadResult = true
                }

                // 停止追踪并重置状态
                locationManager.stopPathTracking()

                // 3 秒后隐藏成功提示
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showUploadResult = false
                        uploadResultMessage = nil
                    }
                }
            }

            // 刷新领地列表（显示新上传的领地）
            await loadTerritories()

        } catch {
            // 上传失败
            await MainActor.run {
                isUploading = false
                showUploadError("上传失败: \(error.localizedDescription)")
            }
        }
    }

    /// 显示上传错误
    private func showUploadError(_ message: String) {
        uploadResultMessage = message
        withAnimation {
            showUploadResult = true
        }

        // 3 秒后隐藏错误提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showUploadResult = false
                uploadResultMessage = nil
            }
        }
    }

    /// 加载所有领地
    private func loadTerritories() async {
        do {
            let loadedTerritories = try await territoryManager.loadAllTerritories()
            await MainActor.run {
                territories = loadedTerritories
            }
            TerritoryLogger.shared.log("加载了 \(loadedTerritories.count) 个领地", type: .info)
        } catch {
            TerritoryLogger.shared.log("加载领地失败: \(error.localizedDescription)", type: .error)
        }
    }
}

// MARK: - Preview

#Preview {
    MapTabView()
}
