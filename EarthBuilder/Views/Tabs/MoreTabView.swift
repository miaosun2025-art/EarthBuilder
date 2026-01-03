import SwiftUI

struct MoreTabView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: SupabaseTestView()) {
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        VStack(alignment: .leading) {
                            Text("Supabase 连接测试")
                                .font(.headline)
                            Text("测试项目与 Supabase 的连接状态")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("更多")
        }
    }
}

#Preview {
    MoreTabView()
}
