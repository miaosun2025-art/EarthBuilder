//
//  TestMenuView.swift
//  EarthBuilder
//
//  开发测试入口菜单
//  包含 Supabase 测试和圈地测试两个入口
//

import SwiftUI

struct TestMenuView: View {

    var body: some View {
        ZStack {
            // 背景
            ApocalypseTheme.background
                .ignoresSafeArea()

            List {
                // Supabase 连接测试
                NavigationLink(destination: SupabaseTestView()) {
                    HStack(spacing: 16) {
                        Image(systemName: "network")
                            .font(.system(size: 24))
                            .foregroundColor(ApocalypseTheme.primary)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Supabase 连接测试")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(ApocalypseTheme.textPrimary)

                            Text("测试项目与 Supabase 的连接状态")
                                .font(.system(size: 13))
                                .foregroundColor(ApocalypseTheme.textSecondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(ApocalypseTheme.cardBackground)

                // 圈地功能测试
                NavigationLink(destination: TerritoryTestView()) {
                    HStack(spacing: 16) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ApocalypseTheme.primary)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("圈地功能测试")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(ApocalypseTheme.textPrimary)

                            Text("实时查看圈地追踪日志")
                                .font(.system(size: 13))
                                .foregroundColor(ApocalypseTheme.textSecondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(ApocalypseTheme.cardBackground)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("开发测试")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        TestMenuView()
    }
}
