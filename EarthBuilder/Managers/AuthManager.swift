import Foundation
import Combine
import Supabase

// MARK: - User Model
/// 用户模型
struct User: Codable, Identifiable {
    let id: UUID
    let email: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
}

// MARK: - AuthManager
/// 认证管理器
/// 负责处理用户注册、登录、找回密码等认证流程
@MainActor
class AuthManager: ObservableObject {

    // MARK: - Published Properties

    /// 是否已完成认证（已登录且完成所有必要流程）
    @Published var isAuthenticated: Bool = false

    /// 是否需要设置密码（OTP 验证后必须设置密码才能完成）
    @Published var needsPasswordSetup: Bool = false

    /// 当前登录用户
    @Published var currentUser: User?

    /// 是否正在加载
    @Published var isLoading: Bool = false

    /// 错误信息
    @Published var errorMessage: String?

    /// OTP 是否已发送
    @Published var otpSent: Bool = false

    /// OTP 是否已验证（验证码已验证，等待设置密码）
    @Published var otpVerified: Bool = false

    /// 是否正在初始化（首次检查会话）
    @Published var isInitializing: Bool = true

    // MARK: - Private Properties

    /// 认证状态监听任务
    private var authStateTask: Task<Void, Never>?

    // MARK: - Initialization

    init() {
        // 初始化时检查会话
        Task {
            await checkSession()
            isInitializing = false
            // 启动认证状态监听
            startAuthStateListener()
        }
    }

    deinit {
        // 取消认证状态监听
        authStateTask?.cancel()
    }

    // MARK: - Registration Flow

    /// 发送注册验证码
    /// - Parameter email: 用户邮箱
    func sendRegisterOTP(email: String) async {
        isLoading = true
        errorMessage = nil
        otpSent = false

        do {
            // 步骤 1：先检查邮箱状态（不发送邮件）
            print("🔍 检查邮箱状态: \(email)")

            // 调用数据库函数检查邮箱状态
            struct EmailStatus: Codable {
                let exists: Bool      // 用户是否存在
                let confirmed: Bool   // 邮箱是否已验证
            }

            let status: EmailStatus = try await supabase.rpc("check_email_status", params: [
                "user_email": email
            ]).execute().value

            print("📊 邮箱状态: exists=\(status.exists), confirmed=\(status.confirmed)")

            // 如果用户已存在且邮箱已验证，不允许注册
            if status.exists && status.confirmed {
                errorMessage = "该邮箱已注册，请直接登录"
                otpSent = false
                isLoading = false
                print("⚠️ 邮箱已注册且已验证: \(email)")
                return
            }

            // 步骤 2：发送注册验证码
            // - 如果用户不存在：创建新用户并发送验证码
            // - 如果用户存在但未验证：重新发送验证码
            if status.exists && !status.confirmed {
                print("📧 重新发送验证码到未验证的邮箱: \(email)")
            } else {
                print("📧 发送注册验证码到新邮箱: \(email)")
            }

            try await supabase.auth.signInWithOTP(
                email: email,
                shouldCreateUser: true
            )

            otpSent = true
            errorMessage = nil
            print("✅ 验证码已发送到: \(email)")
        } catch {
            let errorDesc = error.localizedDescription

            // 处理频率限制错误
            if errorDesc.contains("429") || errorDesc.contains("rate limit") {
                errorMessage = "发送过于频繁，请稍后再试"
            } else {
                errorMessage = "发送验证码失败: \(errorDesc)"
            }

            otpSent = false
            print("❌ 发送验证码失败: \(errorDesc)")
        }

        isLoading = false
    }

    /// 验证注册验证码
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - code: 验证码
    func verifyRegisterOTP(email: String, code: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 验证 OTP，type 为 .email（注册流程）
            let session = try await supabase.auth.verifyOTP(
                email: email,
                token: code,
                type: .email
            )

            // 验证成功，用户已登录
            otpVerified = true
            needsPasswordSetup = true
            // 注意：此时 isAuthenticated 保持 false，必须设置密码才能完成注册

            // 获取用户信息
            let authUser = session.user
            currentUser = User(
                id: authUser.id,
                email: authUser.email,
                createdAt: authUser.createdAt
            )

            errorMessage = nil
        } catch {
            errorMessage = "验证码错误或已过期: \(error.localizedDescription)"
            otpVerified = false
        }

        isLoading = false
    }

    /// 完成注册（设置密码）
    /// - Parameter password: 用户密码
    func completeRegistration(password: String) async {
        guard needsPasswordSetup else {
            errorMessage = "无需设置密码"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // 更新用户密码
            print("🔐 设置密码中...")
            _ = try await supabase.auth.update(
                user: UserAttributes(password: password)
            )

            // 注册完成
            needsPasswordSetup = false
            isAuthenticated = true
            errorMessage = nil
            print("✅ 密码设置成功，注册完成")
        } catch {
            let errorDesc = error.localizedDescription
            print("❌ 设置密码失败: \(errorDesc)")

            // 处理特定错误
            if errorDesc.contains("Password should be at least") ||
               errorDesc.contains("密码长度") {
                errorMessage = "密码长度不符合要求，请输入至少 6 位字符"
            } else {
                errorMessage = "设置密码失败: \(errorDesc)"
            }
        }

        isLoading = false
    }

    // MARK: - Sign In

    /// 使用邮箱和密码登录
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - password: 用户密码
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 使用邮箱密码登录
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            // 登录成功，直接完成认证
            isAuthenticated = true
            needsPasswordSetup = false

            // 获取用户信息
            let authUser = session.user
            currentUser = User(
                id: authUser.id,
                email: authUser.email,
                createdAt: authUser.createdAt
            )

            errorMessage = nil
        } catch {
            errorMessage = "登录失败: \(error.localizedDescription)"
            isAuthenticated = false
        }

        isLoading = false
    }

    // MARK: - Password Reset Flow

    /// 发送找回密码验证码
    /// - Parameter email: 用户邮箱
    func sendResetOTP(email: String) async {
        isLoading = true
        errorMessage = nil
        otpSent = false

        do {
            // 检查邮箱状态
            print("🔍 检查邮箱状态: \(email)")

            struct EmailStatus: Codable {
                let exists: Bool
                let confirmed: Bool
            }

            let status: EmailStatus = try await supabase.rpc("check_email_status", params: [
                "user_email": email
            ]).execute().value

            // 如果邮箱不存在或未验证，不允许重置密码
            if !status.exists || !status.confirmed {
                errorMessage = "该邮箱未注册或未验证"
                otpSent = false
                isLoading = false
                print("⚠️ 邮箱未注册或未验证: \(email)")
                return
            }

            // 发送找回密码的 OTP 验证码
            print("📧 发送找回密码验证码到: \(email)")
            try await supabase.auth.signInWithOTP(
                email: email,
                shouldCreateUser: false
            )

            otpSent = true
            errorMessage = nil
            print("✅ 验证码已发送到: \(email)")
        } catch {
            let errorDesc = error.localizedDescription

            // 处理频率限制错误
            if errorDesc.contains("429") || errorDesc.contains("rate limit") {
                errorMessage = "发送过于频繁，请稍后再试"
            } else {
                errorMessage = "发送验证码失败: \(errorDesc)"
            }

            otpSent = false
            print("❌ 发送验证码失败: \(errorDesc)")
        }

        isLoading = false
    }

    /// 验证找回密码验证码
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - code: 验证码
    func verifyResetOTP(email: String, code: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 找回密码时，使用 .email 类型验证 OTP（因为我们用 signInWithOTP 发送）
            print("🔐 验证找回密码验证码: \(email)")
            let session = try await supabase.auth.verifyOTP(
                email: email,
                token: code,
                type: .email
            )

            // 验证成功
            otpVerified = true
            needsPasswordSetup = true

            // 获取用户信息
            let authUser = session.user
            currentUser = User(
                id: authUser.id,
                email: authUser.email,
                createdAt: authUser.createdAt
            )

            errorMessage = nil
            print("✅ 验证码验证成功")
        } catch {
            let errorDesc = error.localizedDescription
            errorMessage = "验证码错误或已过期: \(errorDesc)"
            otpVerified = false
            print("❌ 验证码验证失败: \(errorDesc)")
        }

        isLoading = false
    }

    /// 重置密码（设置新密码）
    /// - Parameter newPassword: 新密码
    func resetPassword(newPassword: String) async {
        guard needsPasswordSetup else {
            errorMessage = "无需重置密码"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // 更新密码
            print("🔐 重置密码中...")
            _ = try await supabase.auth.update(
                user: UserAttributes(password: newPassword)
            )

            // 密码重置完成
            needsPasswordSetup = false
            isAuthenticated = true
            errorMessage = nil
            print("✅ 密码重置成功")
        } catch {
            let errorDesc = error.localizedDescription
            print("❌ 密码重置失败: \(errorDesc)")

            // 处理特定错误
            if errorDesc.contains("same as the old password") ||
               errorDesc.contains("相同") ||
               errorDesc.contains("same") {
                errorMessage = "新密码不能与旧密码相同，请输入一个新的密码"
            } else if errorDesc.contains("Password should be at least") ||
                      errorDesc.contains("密码长度") {
                errorMessage = "密码长度不符合要求，请输入至少 6 位字符"
            } else {
                errorMessage = "重置密码失败: \(errorDesc)"
            }
        }

        isLoading = false
    }

    // MARK: - Third-Party Authentication (Coming Soon)

    /// 使用 Apple 登录
    /// TODO: 实现 Apple 登录逻辑
    func signInWithApple() async {
        // TODO: 实现 Apple Sign In
        // 1. 获取 Apple ID Credential
        // 2. 调用 supabase.auth.signInWithIdToken(provider: .apple, idToken:)
        // 3. 更新认证状态
        errorMessage = "Apple 登录功能即将推出"
    }

    /// 使用 Google 登录
    func signInWithGoogle() async {
        print("🟢 [认证] 开始 Google 登录流程")
        isLoading = true
        errorMessage = nil

        do {
            // 步骤 1: 使用 Google Sign In 获取凭证
            let googleHelper = GoogleSignInHelper()
            let (idToken, accessToken) = try await googleHelper.signIn()

            print("🟢 [认证] 成功获取 Google 凭证")
            print("📊 [认证] ID Token: \(idToken.prefix(20))...")
            print("📊 [认证] Access Token: \(accessToken.prefix(20))...")

            // 步骤 2: 使用 Google 凭证登录 Supabase
            print("🟢 [认证] 调用 Supabase signInWithIdToken...")

            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .google,
                    idToken: idToken,
                    accessToken: accessToken
                )
            )

            print("✅ [认证] Supabase 登录成功")
            print("📊 [认证] 用户 ID: \(session.user.id)")
            print("📊 [认证] 用户邮箱: \(session.user.email ?? "无邮箱")")

            // 步骤 3: 更新认证状态
            isAuthenticated = true
            needsPasswordSetup = false

            // 获取用户信息
            let authUser = session.user
            currentUser = User(
                id: authUser.id,
                email: authUser.email,
                createdAt: authUser.createdAt
            )

            errorMessage = nil
            print("✅ [认证] Google 登录流程完成")

        } catch {
            let errorDesc = error.localizedDescription
            print("❌ [认证] Google 登录失败: \(errorDesc)")
            errorMessage = "Google 登录失败: \(errorDesc)"
            isAuthenticated = false
        }

        isLoading = false
    }

    // MARK: - Session Management

    /// 登出
    func signOut() async {
        isLoading = true
        errorMessage = nil

        do {
            // 调用 Supabase 登出
            try await supabase.auth.signOut()

            // 清除本地状态
            // 注意：authStateChanges 监听器会自动触发 signedOut 事件
            // 但为了确保状态一致，这里也手动清除
            isAuthenticated = false
            needsPasswordSetup = false
            currentUser = nil
            otpSent = false
            otpVerified = false
            errorMessage = nil

            print("✅ 成功登出")
        } catch {
            errorMessage = "登出失败: \(error.localizedDescription)"
            print("❌ 登出失败: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// 删除用户账户
    /// 调用 Supabase Edge Function 删除当前用户的账户
    func deleteAccount() async -> Bool {
        print("🔴 [认证] 开始删除账户流程")
        isLoading = true
        errorMessage = nil

        do {
            // 获取当前会话的 access token
            let session = try await supabase.auth.session
            let accessToken = session.accessToken

            // 调用 Edge Function
            let url = URL(string: "https://taskfpupruagdzslzpac.supabase.co/functions/v1/delete-account")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            print("🔵 [认证] 调用删除账户 API...")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [认证] 无效的响应")
                errorMessage = "删除账户失败：无效的响应"
                isLoading = false
                return false
            }

            print("📊 [认证] API 响应状态码: \(httpResponse.statusCode)")

            if httpResponse.statusCode == 200 {
                print("✅ [认证] 账户删除成功")

                // 清除本地状态
                isAuthenticated = false
                needsPasswordSetup = false
                currentUser = nil
                otpSent = false
                otpVerified = false
                errorMessage = nil

                isLoading = false
                return true
            } else {
                // 解析错误响应
                if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMsg = errorResponse["error"] {
                    print("❌ [认证] 删除账户失败: \(errorMsg)")
                    errorMessage = "删除账户失败: \(errorMsg)"
                } else {
                    print("❌ [认证] 删除账户失败，状态码: \(httpResponse.statusCode)")
                    errorMessage = "删除账户失败"
                }

                isLoading = false
                return false
            }

        } catch {
            let errorDesc = error.localizedDescription
            print("❌ [认证] 删除账户异常: \(errorDesc)")
            errorMessage = "删除账户失败: \(errorDesc)"
            isLoading = false
            return false
        }
    }

    /// 检查当前会话状态
    func checkSession() async {
        isLoading = true

        do {
            // 获取当前会话
            let session = try await supabase.auth.session

            // 有会话，用户已登录
            let authUser = session.user
            currentUser = User(
                id: authUser.id,
                email: authUser.email,
                createdAt: authUser.createdAt
            )

            // 检查用户是否已设置密码
            // 如果用户通过 OTP 登录但未设置密码，需要强制设置密码
            // 注意：这里可以根据实际业务逻辑调整判断条件
            // 例如检查用户的 app_metadata 或 user_metadata

            isAuthenticated = true
            needsPasswordSetup = false
        } catch {
            // 会话无效或已过期
            // 初始化时不显示错误消息（避免首次打开或正常登出后显示错误）
            handleSessionExpired(showError: !isInitializing)
        }

        isLoading = false
    }

    /// 处理会话过期
    /// - Parameter showError: 是否显示错误消息
    private func handleSessionExpired(showError: Bool = true) {
        // 清除所有认证状态
        isAuthenticated = false
        needsPasswordSetup = false
        currentUser = nil
        otpSent = false
        otpVerified = false

        // 只在需要时显示错误消息
        if showError {
            errorMessage = "会话已过期，请重新登录"
        } else {
            errorMessage = nil
        }

        // authStateChanges 监听器会自动触发 signedOut 事件
        // 不需要手动调用 signOut()
    }

    // MARK: - Helper Methods

    /// 清除错误信息
    func clearError() {
        errorMessage = nil
    }

    /// 重置 OTP 状态
    func resetOTPState() {
        otpSent = false
        otpVerified = false
    }

    // MARK: - Auth State Listener

    /// 启动认证状态监听器
    /// 监听 Supabase 认证状态变化（登录、登出等）
    private func startAuthStateListener() {
        authStateTask = Task {
            // 监听认证状态变化
            for await (event, session) in await supabase.auth.authStateChanges {
                await handleAuthStateChange(event: event, session: session)
            }
        }
    }

    /// 处理认证状态变化
    /// - Parameters:
    ///   - event: 认证状态事件
    ///   - session: 当前会话（可能为 nil）
    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) async {
        print("🔄 认证状态变化: \(event)")

        switch event {
        case .signedIn:
            // 用户登录
            print("✅ 用户已登录")
            if let session = session {
                updateUserFromSession(session)
            } else {
                await updateUserSession()
            }

        case .signedOut:
            // 用户登出
            print("👋 用户已登出")
            isAuthenticated = false
            needsPasswordSetup = false
            currentUser = nil
            otpSent = false
            otpVerified = false

        case .userUpdated:
            // 用户信息更新
            print("🔄 用户信息已更新")
            if let session = session {
                updateUserFromSession(session)
            } else {
                await updateUserSession()
            }

        case .passwordRecovery:
            // 密码恢复
            print("🔑 密码恢复流程")
            needsPasswordSetup = true

        case .tokenRefreshed:
            // Token 刷新
            print("🔄 Token 已刷新")
            if let session = session {
                updateUserFromSession(session)
            }

        default:
            print("⚠️ 未处理的认证事件: \(event)")
            break
        }
    }

    /// 更新用户会话信息（从 API 获取）
    private func updateUserSession() async {
        do {
            let session = try await supabase.auth.session
            updateUserFromSession(session)
        } catch {
            // 会话获取失败或已过期
            handleSessionExpired()
        }
    }

    /// 从会话对象更新用户信息
    /// - Parameter session: Supabase 会话对象
    private func updateUserFromSession(_ session: Session) {
        // 检查会话是否过期
        if session.isExpired {
            print("⚠️ [认证] 会话已过期，需要重新登录")
            handleSessionExpired()
            return
        }

        let authUser = session.user

        currentUser = User(
            id: authUser.id,
            email: authUser.email,
            createdAt: authUser.createdAt
        )

        // 如果不在密码设置流程中，标记为已认证
        if !needsPasswordSetup {
            isAuthenticated = true
        }
    }
}
