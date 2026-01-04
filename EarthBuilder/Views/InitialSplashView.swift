import SwiftUI

/// 初始启动画面（检查会话时显示）
struct InitialSplashView: View {
    @EnvironmentObject var authManager: AuthManager

    /// 是否显示加载动画
    @State private var isAnimating = false

    /// Logo 缩放动画
    @State private var logoScale: CGFloat = 0.8

    /// Logo 透明度
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.10, green: 0.10, blue: 0.18),
                    Color(red: 0.09, green: 0.13, blue: 0.24),
                    Color(red: 0.06, green: 0.06, blue: 0.10)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Logo
                ZStack {
                    // 外圈光晕（呼吸动画）
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.orange.opacity(0.3),
                                    Color.orange.opacity(0)
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: isAnimating
                        )

                    // Logo 圆形背景
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.orange,
                                    Color.orange.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.orange.opacity(0.5), radius: 20)

                    // 地球图标
                    Image(systemName: "globe.asia.australia.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // 标题
                VStack(spacing: 12) {
                    Text("地球新主")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)

                    Text("EARTH BUILDER")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .tracking(4)
                }
                .opacity(logoOpacity)

                Spacer()

                // 加载指示器
                VStack(spacing: 16) {
                    // 三点加载动画
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 10, height: 10)
                                .scaleEffect(isAnimating ? 1.0 : 0.5)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }

                    // 加载文字
                    Text(authManager.isInitializing ? "正在检查会话..." : "加载完成")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - 动画方法

    private func startAnimations() {
        // Logo 入场动画
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // 启动循环动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimating = true
        }
    }
}

#Preview {
    InitialSplashView()
        .environmentObject(AuthManager())
}
