import Foundation
import GoogleSignIn
import Supabase

/// Google 登录辅助类
@MainActor
class GoogleSignInHelper {

    /// Google Client ID
    private let clientID = "908977472998-8e5knp6gb3t78kffhm5glmvh1t3ucu9s.apps.googleusercontent.com"

    /// 执行 Google 登录
    /// - Returns: 返回 (idToken, accessToken) 元组
    func signIn() async throws -> (idToken: String, accessToken: String) {
        print("🔵 [Google登录] 开始执行 Google 登录流程")

        // 获取根视图控制器
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
            print("❌ [Google登录] 无法获取根视图控制器")
            throw GoogleSignInError.noRootViewController
        }

        print("✅ [Google登录] 成功获取根视图控制器")

        // 配置 Google Sign In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        print("🔵 [Google登录] Google Sign In 配置完成，Client ID: \(clientID)")

        do {
            print("🔵 [Google登录] 调用 Google Sign In...")

            // 执行登录
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            print("✅ [Google登录] Google Sign In 成功")
            print("📊 [Google登录] 用户信息: \(result.user.profile?.email ?? "无邮箱")")

            // 获取 ID Token
            guard let idToken = result.user.idToken?.tokenString else {
                print("❌ [Google登录] 无法获取 ID Token")
                throw GoogleSignInError.noIDToken
            }

            print("✅ [Google登录] 成功获取 ID Token: \(idToken.prefix(20))...")

            // 获取 Access Token
            let accessToken = result.user.accessToken.tokenString
            print("✅ [Google登录] 成功获取 Access Token: \(accessToken.prefix(20))...")

            return (idToken: idToken, accessToken: accessToken)

        } catch {
            print("❌ [Google登录] 登录失败: \(error.localizedDescription)")
            throw error
        }
    }

    /// 登出
    func signOut() {
        print("🔵 [Google登录] 执行 Google 登出")
        GIDSignIn.sharedInstance.signOut()
        print("✅ [Google登录] Google 登出完成")
    }
}

// MARK: - Errors

enum GoogleSignInError: LocalizedError {
    case noRootViewController
    case noIDToken

    var errorDescription: String? {
        switch self {
        case .noRootViewController:
            return "无法获取根视图控制器"
        case .noIDToken:
            return "无法获取 Google ID Token"
        }
    }
}
