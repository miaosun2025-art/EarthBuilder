import SwiftUI
import Supabase

struct ProfileTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showLogoutConfirmation = false

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
        }
    }

    // MARK: - Helper Views

    private func settingRow(icon: String, title: String, subtitle: String) -> some View {
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

#Preview {
    ProfileTabView()
        .environmentObject(AuthManager())
}
