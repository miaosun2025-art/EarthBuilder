import SwiftUI
import Supabase

struct ProfileTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showLogoutConfirmation = false
    @State private var showDeleteAccountDialog = false
    @State private var deleteConfirmationText = ""
    @State private var showDeleteAccountAlert = false
    @State private var deleteAccountError: String?

    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color(red: 0.11, green: 0.12, blue: 0.15).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 40) {
                        // 用户信息卡片
                        VStack(spacing: 20) {
                            // 头像
                            ZStack {
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
                                    .frame(width: 100, height: 100)
                                    .shadow(color: Color.orange.opacity(0.3), radius: 10)

                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 20)

                            // 用户名（从邮箱提取）
                            if let email = authManager.currentUser?.email {
                                Text(extractUsername(from: email))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)

                                // 邮箱
                                Text(email)
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }

                            // 用户 ID
                            if let userId = authManager.currentUser?.id {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.text.rectangle")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 14))

                                    Text("ID: \(userId.uuidString.prefix(8))...")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                            }

                            // 加入时间
                            if let createdAt = authManager.currentUser?.createdAt {
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 14))

                                    Text("加入时间: \(formatDate(createdAt))")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.vertical, 30)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // 功能列表
                        VStack(spacing: 0) {
                            // 账号设置
                            NavigationLink(destination: Text("账号设置")) {
                                settingRow(
                                    icon: "person.circle",
                                    title: "账号设置",
                                    subtitle: "修改个人信息"
                                )
                            }

                            Divider()
                                .background(Color.gray.opacity(0.2))
                                .padding(.leading, 60)

                            // 安全设置
                            NavigationLink(destination: Text("安全设置")) {
                                settingRow(
                                    icon: "lock.shield",
                                    title: "安全设置",
                                    subtitle: "修改密码、绑定邮箱"
                                )
                            }

                            Divider()
                                .background(Color.gray.opacity(0.2))
                                .padding(.leading, 60)

                            // 关于
                            NavigationLink(destination: Text("关于")) {
                                settingRow(
                                    icon: "info.circle",
                                    title: "关于",
                                    subtitle: "版本信息、用户协议"
                                )
                            }
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)

                        Spacer()

                        // 退出登录按钮
                        Button(action: {
                            showLogoutConfirmation = true
                        }) {
                            HStack(spacing: 12) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 18))
                                }

                                Text(authManager.isLoading ? "退出中..." : "退出登录")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(27)
                            .shadow(color: Color.red.opacity(0.3), radius: 10)
                        }
                        .disabled(authManager.isLoading)
                        .padding(.horizontal, 20)

                        // 删除账户按钮
                        Button(action: {
                            print("🔴 [设置] 用户点击删除账户按钮")
                            showDeleteAccountDialog = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "trash.circle")
                                    .font(.system(size: 18))

                                Text("删除账户")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(27)
                            .overlay(
                                RoundedRectangle(cornerRadius: 27)
                                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .disabled(authManager.isLoading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("个人")
            .navigationBarTitleDisplayMode(.inline)
            .alert("确认退出", isPresented: $showLogoutConfirmation) {
                Button("取消", role: .cancel) { }
                Button("退出", role: .destructive) {
                    Task {
                        await authManager.signOut()
                    }
                }
            } message: {
                Text("确定要退出登录吗？")
            }
            .sheet(isPresented: $showDeleteAccountDialog) {
                DeleteAccountConfirmationView(
                    isPresented: $showDeleteAccountDialog,
                    confirmationText: $deleteConfirmationText,
                    onConfirm: {
                        print("📝 [设置] 用户确认删除账户")
                        Task {
                            await performDeleteAccount()
                        }
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .alert("删除账户失败", isPresented: $showDeleteAccountAlert) {
                Button("确定", role: .cancel) {
                    deleteAccountError = nil
                }
            } message: {
                if let error = deleteAccountError {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Delete Account

    /// 执行删除账户操作
    private func performDeleteAccount() async {
        print("🔴 [设置] 开始执行删除账户操作")

        let success = await authManager.deleteAccount()

        if success {
            print("✅ [设置] 账户删除成功")
            // 关闭对话框
            await MainActor.run {
                showDeleteAccountDialog = false
                deleteConfirmationText = ""
            }
        } else {
            print("❌ [设置] 账户删除失败")
            // 显示错误信息
            await MainActor.run {
                deleteAccountError = authManager.errorMessage ?? "删除账户失败，请稍后重试"
                showDeleteAccountAlert = true
                showDeleteAccountDialog = false
                deleteConfirmationText = ""
            }
        }
    }

    // MARK: - Helper Views

    private func settingRow(icon: String, title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .foregroundColor(.orange)
                    .font(.system(size: 20))
            }

            // 文字
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            Spacer()

            // 箭头
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    // MARK: - Helper Methods

    /// 从邮箱提取用户名
    private func extractUsername(from email: String) -> String {
        if let atIndex = email.firstIndex(of: "@") {
            return String(email[..<atIndex])
        }
        return email
    }

    /// 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - Delete Account Confirmation View

struct DeleteAccountConfirmationView: View {
    @Binding var isPresented: Bool
    @Binding var confirmationText: String
    let onConfirm: () -> Void
    @StateObject private var languageManager = LanguageManager.shared

    // 根据当前语言环境确定正确的确认文本
    private var expectedConfirmationText: String {
        let langCode = languageManager.currentLanguageCode
        return langCode.starts(with: "zh") ? "删除" : "DELETE"
    }

    // 检查用户输入是否匹配（支持中英文）
    private var isConfirmationValid: Bool {
        confirmationText == "删除" || confirmationText == "DELETE"
    }

    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color(red: 0.11, green: 0.12, blue: 0.15).ignoresSafeArea()

                VStack(spacing: 24) {
                    // 警告图标
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 80, height: 80)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                    }
                    .padding(.top, 20)

                    // 标题
                    Text("删除账户")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    // 警告文字
                    VStack(spacing: 12) {
                        Text("此操作无法撤销！")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)

                        Text("删除账户后，您的所有数据将被永久删除，包括：")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)

                        VStack(alignment: .leading, spacing: 8) {
                            Label("个人资料和设置", systemImage: "person.fill")
                            Label("所有游戏进度", systemImage: "gamecontroller.fill")
                            Label("成就和奖励", systemImage: "trophy.fill")
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 20)

                    // 确认输入框
                    VStack(alignment: .leading, spacing: 8) {
                        Text("请输入 \"\(expectedConfirmationText)\" 以确认")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))

                        TextField("", text: $confirmationText)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isConfirmationValid ? Color.red : Color.gray.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onChange(of: confirmationText) { _, newValue in
                                print("📝 [设置] 用户输入确认文本: \"\(newValue)\"")
                            }
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    // 按钮
                    VStack(spacing: 12) {
                        // 确认删除按钮
                        Button(action: {
                            print("🔴 [设置] 用户点击确认删除按钮，输入文本: \"\(confirmationText)\"")
                            if isConfirmationValid {
                                print("✅ [设置] 确认文本正确，执行删除操作")
                                onConfirm()
                            } else {
                                print("⚠️ [设置] 确认文本不正确，当前输入: \"\(confirmationText)\"，期望: \"\(expectedConfirmationText)\"")
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 18))

                                Text("确认删除")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                isConfirmationValid
                                    ? LinearGradient(
                                        colors: [Color.red, Color.red.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                            )
                            .cornerRadius(27)
                            .shadow(
                                color: isConfirmationValid ? Color.red.opacity(0.3) : Color.clear,
                                radius: 10
                            )
                        }
                        .disabled(!isConfirmationValid)

                        // 取消按钮
                        Button(action: {
                            print("🔵 [设置] 用户点击取消删除")
                            confirmationText = ""
                            isPresented = false
                        }) {
                            Text("取消")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(27)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("确认删除")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        print("🔵 [设置] 用户点击关闭按钮")
                        confirmationText = ""
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileTabView()
        .environmentObject(AuthManager())
}
