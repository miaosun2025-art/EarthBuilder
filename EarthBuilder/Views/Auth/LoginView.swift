import SwiftUI

/// 登录视图（匹配设计图）
struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var showRegister: Bool = false
    @State private var showForgotPassword: Bool = false
    @State private var isLoginMode: Bool = true // true=登录模式, false=注册模式

    var body: some View {
        ZStack {
            // 背景
            Color(red: 0.11, green: 0.12, blue: 0.15).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Logo
                    ZStack {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 120, height: 120)

                        // 地球剪影图标
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 70))
                            .foregroundColor(Color(red: 0.11, green: 0.12, blue: 0.15))
                    }
                    .padding(.top, 80)

                    // 标题
                    Text("地球新主")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 24)

                    // 副标题
                    Text("征服世界，从脚下开始")
                        .font(.system(size: 16))
                        .foregroundColor(Color.gray.opacity(0.8))
                        .padding(.top, 12)

                    // 登录/注册切换按钮
                    HStack(spacing: 16) {
                        // 登录按钮
                        Button(action: {
                            isLoginMode = true
                        }) {
                            Text("登录")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(isLoginMode ? .white : Color.gray.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(isLoginMode ? Color.orange : Color.clear)
                                .cornerRadius(25)
                        }

                        // 注册按钮
                        Button(action: {
                            showRegister = true
                        }) {
                            Text("注册")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.gray.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 40)

                    // 邮箱输入
                    HStack(spacing: 12) {
                        Image(systemName: "envelope")
                            .foregroundColor(Color.gray.opacity(0.6))
                            .frame(width: 24)

                        TextField("", text: $email)
                            .placeholder(when: email.isEmpty) {
                                Text("邮箱").foregroundColor(Color.gray.opacity(0.5))
                            }
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 40)
                    .padding(.top, 32)

                    // 密码输入
                    HStack(spacing: 12) {
                        Image(systemName: "lock")
                            .foregroundColor(Color.gray.opacity(0.6))
                            .frame(width: 24)

                        if showPassword {
                            TextField("", text: $password)
                                .placeholder(when: password.isEmpty) {
                                    Text("密码").foregroundColor(Color.gray.opacity(0.5))
                                }
                                .textContentType(.password)
                                .foregroundColor(.white)
                        } else {
                            SecureField("", text: $password)
                                .placeholder(when: password.isEmpty) {
                                    Text("密码").foregroundColor(Color.gray.opacity(0.5))
                                }
                                .textContentType(.password)
                                .foregroundColor(.white)
                        }

                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(Color.gray.opacity(0.6))
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 40)
                    .padding(.top, 16)

                    // 错误提示
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 12)
                    }

                    // 登录按钮
                    Button(action: {
                        Task {
                            await authManager.signIn(email: email, password: password)
                        }
                    }) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(authManager.isLoading ? "登录中..." : "登录")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isLoginEnabled ? Color.gray.opacity(0.3) : Color.gray.opacity(0.15))
                        .cornerRadius(28)
                    }
                    .disabled(!isLoginEnabled || authManager.isLoading)
                    .padding(.horizontal, 40)
                    .padding(.top, 24)

                    // 忘记密码
                    Button(action: {
                        showForgotPassword = true
                    }) {
                        Text("忘记密码?")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 16)

                    // 分隔线
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)

                        Text("或者使用以下方式登录")
                            .font(.system(size: 13))
                            .foregroundColor(Color.gray.opacity(0.6))
                            .lineLimit(1)
                            .fixedSize()

                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 32)

                    // Apple 登录
                    Button(action: {
                        Task {
                            await authManager.signInWithApple()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 20, weight: .semibold))

                            Text("通过 Apple 登录")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black)
                        .cornerRadius(28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 24)

                    // Google 登录
                    Button(action: {
                        Task {
                            await authManager.signInWithGoogle()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20, weight: .semibold))

                            Text("通过 Google 登录")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.white)
                        .cornerRadius(28)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
                .environmentObject(authManager)
        }
    }

    /// 是否可以登录
    private var isLoginEnabled: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
}

// MARK: - Placeholder Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
