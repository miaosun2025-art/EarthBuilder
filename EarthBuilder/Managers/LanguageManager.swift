import Foundation
import SwiftUI
import Combine

// MARK: - Language

/// 支持的语言
enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"      // 跟随系统
    case chinese = "zh-Hans"    // 简体中文
    case english = "en"         // English

    var id: String { rawValue }

    /// 显示名称
    var displayName: String {
        switch self {
        case .system:
            return "跟随系统 / Follow System"
        case .chinese:
            return "简体中文"
        case .english:
            return "English"
        }
    }

    /// 获取实际的语言代码
    var languageCode: String? {
        switch self {
        case .system:
            return nil  // 使用系统语言
        case .chinese:
            return "zh-Hans"
        case .english:
            return "en"
        }
    }
}

// MARK: - LanguageManager

/// 语言管理器
/// 负责管理应用内的语言切换
class LanguageManager: ObservableObject {

    // MARK: - Singleton

    static let shared = LanguageManager()

    // MARK: - Published Properties

    /// 当前选择的语言
    @Published var currentLanguage: AppLanguage {
        didSet {
            // 保存到 UserDefaults
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
            print("🌍 [语言] 语言已切换为: \(currentLanguage.displayName)")

            // 更新 Bundle
            updateLanguageBundle()
        }
    }

    /// 当前语言的 Bundle
    @Published private(set) var languageBundle: Bundle = Bundle.main

    // MARK: - Initialization

    private init() {
        // 从 UserDefaults 读取保存的语言设置
        if let savedLanguage = UserDefaults.standard.string(forKey: "app_language"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
            print("🌍 [语言] 从本地加载语言设置: \(language.displayName)")
        } else {
            self.currentLanguage = .system
            print("🌍 [语言] 使用默认语言设置: 跟随系统")
        }

        // 初始化 Bundle
        updateLanguageBundle()
    }

    // MARK: - Public Methods

    /// 切换语言
    /// - Parameter language: 目标语言
    func switchLanguage(to language: AppLanguage) {
        print("🌍 [语言] 请求切换语言: \(language.displayName)")
        currentLanguage = language
    }

    /// 获取本地化字符串
    /// - Parameters:
    ///   - key: 字符串键
    ///   - comment: 注释
    /// - Returns: 本地化后的字符串
    func localizedString(_ key: String, comment: String = "") -> String {
        return languageBundle.localizedString(forKey: key, value: nil, table: nil)
    }

    /// 获取当前实际使用的语言代码
    var currentLanguageCode: String {
        if currentLanguage == .system {
            // 获取系统语言
            let systemLanguage = Locale.preferredLanguages.first ?? "en"
            if systemLanguage.starts(with: "zh") {
                return "zh-Hans"
            } else {
                return "en"
            }
        } else {
            return currentLanguage.languageCode ?? "en"
        }
    }

    // MARK: - Private Methods

    /// 更新语言 Bundle
    private func updateLanguageBundle() {
        let languageCode = currentLanguageCode

        print("🌍 [语言] 更新 Bundle，语言代码: \(languageCode)")

        // 尝试获取对应语言的 Bundle
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.languageBundle = bundle
            print("✅ [语言] 成功加载语言 Bundle: \(languageCode)")
        } else {
            // 如果找不到，使用主 Bundle
            self.languageBundle = Bundle.main
            print("⚠️ [语言] 未找到语言 Bundle: \(languageCode)，使用主 Bundle")
        }
    }
}

// MARK: - String Extension

extension String {
    /// 快捷本地化方法
    var localized: String {
        return LanguageManager.shared.localizedString(self)
    }

    /// 本地化方法（带参数）
    /// - Parameter arguments: 格式化参数
    /// - Returns: 格式化后的本地化字符串
    func localized(_ arguments: CVarArg...) -> String {
        let format = LanguageManager.shared.localizedString(self)
        return String(format: format, arguments: arguments)
    }
}
