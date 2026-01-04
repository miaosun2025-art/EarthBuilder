import SwiftUI

/// 忘记密码视图
struct ForgotPasswordView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var email: String = ""
    @State private var verificationCode: String = ""
    @State private var step: ForgotPasswordStep = .inputEmail

    enum ForgotPasswordStep {
        case inputEmail      // 输入邮箱
        case inputCode       // 输入验证码
    }

    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        // 标题
                        VStack(spacing: 16) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                                .padding(.top, 40)

                            Text(step == .inputEmail ? "找回密码" : "验证邮箱")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text(step == .inputEmail ? "输入注册邮箱" : "请输入发送到邮箱的验证码")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 40)

                        // 根据步骤显示不同内容
                        if step == .inputEmail {
                            emailInputSection
                        } else {
                            codeInputSection
                        }

                        // 错误提示
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }

                        // 操作按钮
                        actionButton

                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    // MARK: - Email Input Section
    private var emailInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("邮箱")
                .font(.system(size: 14))
                .foregroundColor(.gray)

            TextField("", text: $email)
                .placeholder(when: email.isEmpty) {
                    Text("请输入注册邮箱").foregroundColor(.gray.opacity(0.5))
                }
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Code Input Section
    private var codeInputSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("验证码")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)

                // 邮件提醒
                if authManager.otpSent {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)

                        Text("验证码已发送到 \(email)")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)

                    Text("📮 收不到验证码？请检查邮箱的垃圾邮件/spam文件夹")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 4)
                }

                TextField("", text: $verificationCode)
                    .placeholder(when: verificationCode.isEmpty) {
                        Text("请输入 6 位验证码").foregroundColor(.gray.opacity(0.5))
                    }
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }

            // 重新发送验证码
            Button(action: {
                Task {
                    await authManager.sendResetOTP(email: email)
                }
            }) {
                Text("重新发送验证码")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Action Button
    private var actionButton: some View {
        Button(action: handleAction) {
            HStack {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(buttonTitle)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isActionEnabled ? Color.orange : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(!isActionEnabled || authManager.isLoading)
        .padding(.horizontal, 30)
    }

    // MARK: - Helpers
    private var buttonTitle: String {
        if authManager.isLoading {
            return step == .inputEmail ? "发送中..." : "验证中..."
        }
        return step == .inputEmail ? "发送验证码" : "验证"
    }

    private var isActionEnabled: Bool {
        switch step {
        case .inputEmail:
            return !email.isEmpty && email.contains("@")
        case .inputCode:
            return verificationCode.count == 6
        }
    }

    private func handleAction() {
        Task {
            switch step {
            case .inputEmail:
                await authManager.sendResetOTP(email: email)
                if authManager.otpSent {
                    step = .inputCode
                }
            case .inputCode:
                await authManager.verifyResetOTP(email: email, code: verificationCode)
                // 验证成功后会自动关闭 sheet，RootView 会显示设置密码页面
                if authManager.otpVerified {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(AuthManager())
}
