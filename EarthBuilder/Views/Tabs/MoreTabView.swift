import SwiftUI

struct MoreTabView: View {
    @StateObject private var languageManager = LanguageManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color(red: 0.11, green: 0.12, blue: 0.15).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 标题区域
                        VStack(spacing: 12) {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                                .padding(.top, 20)

                            Text("更多")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("探索和圈占领地")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 10)

                        // 设置列表
                        VStack(spacing: 0) {
                            // 语言设置
                            NavigationLink(destination: LanguageSettingsView()) {
                                settingRow(
                                    icon: "globe",
                                    title: "语言 / Language",
                                    subtitle: languageManager.currentLanguage.displayName
                                )
                            }

                            Divider()
                                .background(Color.gray.opacity(0.2))
                                .padding(.leading, 60)

                            // Supabase 连接测试
                            NavigationLink(destination: SupabaseTestView()) {
                                settingRow(
                                    icon: "network",
                                    title: "Supabase 连接测试",
                                    subtitle: "测试项目与 Supabase 的连接状态"
                                )
                            }
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)

                        Spacer()
                    }
                }
            }
            .navigationTitle("更多")
            .navigationBarTitleDisplayMode(.inline)
            .id(languageManager.refreshID) // 强制刷新
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

    // Overload for dynamic String subtitle (e.g., language display name)
    private func settingRow(icon: String, title: LocalizedStringKey, subtitle: String) -> some View {
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

                Text(verbatim: subtitle)
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
}

#Preview {
    MoreTabView()
}
