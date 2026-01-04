import SwiftUI

/// 设置密码视图（用于注册和重置密码）
struct SetPasswordView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    var isResetPassword: Bool = false

    var body: some View {
        ZStack {
            // 背景
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    // 标题
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                            .padding(.top, 60)

                        Text("设置密码")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        VStack(spacing: 8) {
                            Text("请设置一个安全的密码")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)

                            // 重置密码提示
                            if authManager.currentUser != nil {
                                Text("⚠️ 新密码不能与旧密码相同")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .padding(.bottom, 40)

                    // 密码输入
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("密码")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)

                            SecureField("", text: $password)
                                .placeholder(when: password.isEmpty) {
                                    Text("至少 6 位字符").foregroundColor(.gray.opacity(0.5))
                                }
                                .textContentType(.newPassword)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("确认密码")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)

                            SecureField("", text: $confirmPassword)
                                .placeholder(when: confirmPassword.isEmpty) {
                                    Text("再次输入密码").foregroundColor(.gray.opacity(0.5))
                                }
                                .textContentType(.newPassword)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        }

                        // 密码强度提示
                        VStack(alignment: .leading, spacing: 8) {
                            passwordStrengthItem(
                                text: "至少 6 位字符",
                                isValid: password.count >= 6
                            )
                            passwordStrengthItem(
                                text: "两次密码一致",
                                isValid: !password.isEmpty && password == confirmPassword
                            )
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 30)

                    // 错误提示
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }

                    // 完成按钮
                    Button(action: {
                        Task {
                            if isResetPassword {
                                await authManager.resetPassword(newPassword: password)
                            } else {
                                await authManager.completeRegistration(password: password)
                            }
                        }
                    }) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(authManager.isLoading ? "设置中..." : "完成")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isPasswordValid ? Color.orange : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isPasswordValid || authManager.isLoading)
                    .padding(.horizontal, 30)

                    Spacer()
                }
            }
        }
    }

    // MARK: - Password Strength Item
    private func passwordStrengthItem(text: String, isValid: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .gray)
                .font(.system(size: 16))

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(isValid ? .white : .gray)
        }
    }

    // MARK: - Validation
    private var isPasswordValid: Bool {
        password.count >= 6 && password == confirmPassword
    }
}

#Preview {
    SetPasswordView()
        .environmentObject(AuthManager())
}
