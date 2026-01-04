import SwiftUI

/// 根视图：控制认证、启动页与主界面的切换
struct RootView: View {
    @EnvironmentObject var authManager: AuthManager

    /// 启动页是否完成（登录后的启动画面）
    @State private var splashFinished = false

    var body: some View {
        ZStack {
            if authManager.isInitializing {
                // 正在初始化（检查会话）
                InitialSplashView()
                    .environmentObject(authManager)
                    .transition(.opacity)
            } else if authManager.needsPasswordSetup {
                // 需要设置密码（注册或重置密码流程）
                SetPasswordView()
                    .environmentObject(authManager)
                    .transition(.opacity)
            } else if authManager.isAuthenticated {
                // 已完成认证，显示启动页和主界面
                if splashFinished {
                    MainTabView()
                        .environmentObject(authManager)
                        .transition(.opacity)
                } else {
                    SplashView(isFinished: $splashFinished)
                        .transition(.opacity)
                }
            } else {
                // 未登录，显示登录页面
                LoginView()
                    .environmentObject(authManager)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isInitializing)
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authManager.needsPasswordSetup)
        .animation(.easeInOut(duration: 0.3), value: splashFinished)
        .onChange(of: authManager.isAuthenticated) { _, isAuth in
            // 当认证状态变为 true 时，重置启动页状态
            if isAuth {
                splashFinished = false
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthManager())
}
