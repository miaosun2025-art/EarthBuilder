import SwiftUI
import Supabase

struct SupabaseTestView: View {
    @State private var isConnected: Bool? = nil
    @State private var debugLog: String = "点击按钮开始测试连接..."
    @State private var isTesting: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 状态图标
                if let connected = isConnected {
                    Image(systemName: connected ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(connected ? .green : .red)
                        .padding(.top, 40)
                } else {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                }

                // 调试日志文本框
                ScrollView {
                    Text(debugLog)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
                .frame(height: 300)
                .padding(.horizontal)

                // 测试连接按钮
                Button(action: testConnection) {
                    HStack {
                        if isTesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isTesting ? "测试中..." : "测试连接")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isTesting ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isTesting)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Supabase 连接测试")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func testConnection() {
        isTesting = true
        debugLog = "开始测试连接...\n"
        debugLog += "目标 URL: https://taskfpupruagdzslzpac.supabase.co\n"
        debugLog += "正在发送请求...\n\n"

        Task {
            do {
                // 故意查询一个不存在的表来测试连接
                debugLog += "尝试查询不存在的表...\n"
                let _: [String] = try await supabase
                    .from("non_existent_table")
                    .select()
                    .execute()
                    .value

                // 如果执行到这里，说明表存在（不太可能）
                await MainActor.run {
                    debugLog += "✅ 意外成功：表存在\n"
                    isConnected = true
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = error.localizedDescription
                    debugLog += "收到错误响应：\n\(errorMessage)\n\n"

                    // 判断错误类型
                    if errorMessage.contains("PGRST") ||
                       errorMessage.contains("Could not find the table") ||
                       errorMessage.contains("relation") && errorMessage.contains("does not exist") {
                        // PostgreSQL 返回了错误，说明连接成功
                        debugLog += "✅ 连接成功（服务器已响应）\n"
                        debugLog += "Supabase 服务器正常工作，数据库连接正常。\n"
                        isConnected = true
                    } else if errorMessage.contains("hostname") ||
                              errorMessage.contains("URL") ||
                              errorMessage.contains("NSURLErrorDomain") {
                        // 网络或 URL 错误
                        debugLog += "❌ 连接失败：URL 错误或无网络\n"
                        debugLog += "请检查网络连接或 Supabase URL 配置。\n"
                        isConnected = false
                    } else {
                        // 其他未知错误
                        debugLog += "⚠️ 未知错误：\n\(errorMessage)\n"
                        isConnected = false
                    }

                    isTesting = false
                }
            }
        }
    }
}

#Preview {
    SupabaseTestView()
}
