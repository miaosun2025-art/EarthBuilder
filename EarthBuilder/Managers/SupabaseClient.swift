import Foundation
import Supabase

// 共享的 Supabase Client 实例
// 在整个应用中使用同一个 client 实例
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://taskfpupruagdzslzpac.supabase.co")!,
    supabaseKey: "sb_publishable_rAh_7bJMg7A87nSc9SVlBA_nQI28cCH",
    options: SupabaseClientOptions(
        auth: SupabaseClientOptions.AuthOptions(
            // 启用新的会话管理行为：始终发出本地存储的会话
            // 确保本地存储的会话始终被发出，无论其有效性或过期状态
            emitLocalSessionAsInitialSession: true
        )
    )
)
