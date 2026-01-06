//
//  TerritoryLogger.swift
//  EarthBuilder
//
//  圈地功能日志管理器
//  用于在 App 内显示调试日志，方便真机测试时查看运行状态
//

import Foundation
import Combine

/// 日志类型
enum LogType: String {
    case info = "INFO"
    case success = "SUCCESS"
    case warning = "WARNING"
    case error = "ERROR"
}

/// 日志条目
struct LogEntry: Identifiable {
    let id: UUID
    let timestamp: Date
    let message: String
    let type: LogType

    init(message: String, type: LogType) {
        self.id = UUID()
        self.timestamp = Date()
        self.message = message
        self.type = type
    }

    /// 格式化显示（时:分:秒）
    var displayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return "[\(formatter.string(from: timestamp))] [\(type.rawValue)] \(message)"
    }

    /// 格式化导出（完整时间戳）
    var exportString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return "[\(formatter.string(from: timestamp))] [\(type.rawValue)] \(message)"
    }
}

/// 圈地功能日志管理器
/// 单例模式 + ObservableObject，支持 SwiftUI 数据绑定
class TerritoryLogger: ObservableObject {

    // MARK: - Singleton

    static let shared = TerritoryLogger()

    // MARK: - Properties

    /// 日志数组
    @Published var logs: [LogEntry] = []

    /// 格式化的日志文本（用于显示）
    @Published var logText: String = ""

    /// 最大日志条数（防止内存溢出）
    private let maxLogCount = 200

    // MARK: - Initialization

    private init() {
        print("🪵 [日志] TerritoryLogger 初始化")
    }

    // MARK: - Public Methods

    /// 添加日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - type: 日志类型
    func log(_ message: String, type: LogType = .info) {
        DispatchQueue.main.async {
            // 创建日志条目
            let entry = LogEntry(message: message, type: type)

            // 添加到数组
            self.logs.append(entry)

            // 限制日志数量，移除最旧的日志
            if self.logs.count > self.maxLogCount {
                self.logs.removeFirst(self.logs.count - self.maxLogCount)
            }

            // 更新日志文本
            self.updateLogText()

            print("🪵 [\(type.rawValue)] \(message)")
        }
    }

    /// 清空所有日志
    func clear() {
        DispatchQueue.main.async {
            self.logs.removeAll()
            self.logText = ""
            print("🪵 [日志] 日志已清空")
        }
    }

    /// 导出日志为文本
    /// - Returns: 格式化的日志文本（包含头信息）
    func export() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var result = ""
        result += "=== 圈地功能测试日志 ===\n"
        result += "导出时间: \(formatter.string(from: Date()))\n"
        result += "日志条数: \(logs.count)\n"
        result += "\n"

        for entry in logs {
            result += entry.exportString + "\n"
        }

        return result
    }

    // MARK: - Private Methods

    /// 更新日志文本
    private func updateLogText() {
        logText = logs.map { $0.displayString }.joined(separator: "\n")
    }
}
