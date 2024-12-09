//
//  ContentView.swift
//  Lees
//
//  Created by Logan Janssen | Codify on 9/12/2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                BookListView()
            }
            .tabItem {
                Label("Books", systemImage: "book.closed")
            }
            
            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
        }
    }
}

#Preview {
    ContentView()
}
