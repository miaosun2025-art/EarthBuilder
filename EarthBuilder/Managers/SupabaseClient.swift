import Foundation
import Supabase

// 共享的 Supabase Client 实例
// 在整个应用中使用同一个 client 实例
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://taskfpupruagdzslzpac.supabase.co")!,
    supabaseKey: "sb_publishable_rAh_7bJMg7A87nSc9SVlBA_nQI28cCH"
)
