import UIKit
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("🚀 [AppDelegate] 应用启动完成")
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        print("🔗 [AppDelegate] 收到 URL 回调: \(url)")

        // 处理 Google Sign In 的回调
        let handled = GIDSignIn.sharedInstance.handle(url)

        if handled {
            print("✅ [AppDelegate] Google Sign In 成功处理 URL 回调")
        } else {
            print("⚠️ [AppDelegate] URL 回调未被 Google Sign In 处理")
        }

        return handled
    }
}
