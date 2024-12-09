//
//  BookListView.swift
//  Lees
//
//  Created by Logan Janssen | Codify on 9/12/2024.
//

import SwiftUI
import SwiftData

struct BookListView: View {
    @Environment(\.modelContext) private var context
    @Query private var books: [Book]  // SwiftData @Query property wrapper

    @State private var showingAddBookSheet = false

    var body: some View {
        List {
            ForEach(books) { book in
                NavigationLink(value: book) {
                    Text("\(book.title) by \(book.author)")
                }
            }
        }
        .navigationTitle("My Books")
        .navigationDestination(for: Book.self) { book in
            BookDetailView(book: book)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddBookSheet = true }) {
                    Label("Add Book", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddBookSheet) {
            AddBookView()
        }
    }
}

#Preview { ContentView() }
