import SwiftUI

struct LanguageSettingsView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // 背景
            Color(red: 0.11, green: 0.12, blue: 0.15).ignoresSafeArea()

            VStack(spacing: 20) {
                // 说明文字
                VStack(spacing: 8) {
                    Text("选择语言")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)

                    Text("切换后立即生效")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)

                // 语言选项列表
                VStack(spacing: 0) {
                    ForEach(AppLanguage.allCases) { language in
                        Button(action: {
                            print("🌍 [语言设置] 用户选择语言: \(language.displayName)")
                            withAnimation(.easeInOut(duration: 0.3)) {
                                languageManager.switchLanguage(to: language)
                            }
                        }) {
                            languageOption(
                                language: language,
                                isSelected: languageManager.currentLanguage == language
                            )
                        }

                        if language != AppLanguage.allCases.last {
                            Divider()
                                .background(Color.gray.opacity(0.2))
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
                .padding(.horizontal, 20)

                Spacer()

                // 提示信息
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                        Text("语言设置会立即应用到整个应用")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.gray)

                    Text("无需重启应用")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.8))
                }
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("语言设置 / Language")
        .navigationBarTitleDisplayMode(.inline)
        .id(languageManager.refreshID) // 强制刷新
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func languageOption(language: AppLanguage, isSelected: Bool) -> some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(isSelected ? Color.orange.opacity(0.2) : Color.white.opacity(0.1))
                    .frame(width: 44, height: 44)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 24))
                } else {
                    Image(systemName: "globe")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                }
            }

            // 语言名称
            VStack(alignment: .leading, spacing: 4) {
                Text(language.displayName)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(.white)

                // 当前使用的语言代码
                if language == .system {
                    Text(String(format: NSLocalizedString("当前: %@", comment: ""), systemLanguageDisplayName))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // 选中指示器
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.orange)
                    .font(.system(size: 16, weight: .semibold))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    /// 系统语言的显示名称
    private var systemLanguageDisplayName: String {
        let systemLanguage = Locale.preferredLanguages.first ?? "en"
        if systemLanguage.starts(with: "zh") {
            return "简体中文"
        } else {
            return "English"
        }
    }
}

#Preview {
    NavigationView {
        LanguageSettingsView()
    }
}
