//
//  ContentView.swift
//  EarthBuilder
//
//  Created by miao on 2026/1/3.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")

            Spacer()
                .frame(height: 40)

            Text("Developed by [Mia]")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
