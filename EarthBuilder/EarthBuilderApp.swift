//
//  EarthBuilderApp.swift
//  EarthBuilder
//
//  Created by miao on 2026/1/3.
//

import SwiftUI

@main
struct EarthBuilderApp: App {
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
        }
    }
}
