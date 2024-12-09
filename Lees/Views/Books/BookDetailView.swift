//
//  BookDetailView.swift
//  Lees
//
//  Created by Logan Janssen | Codify on 9/12/2024.
//

import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Environment(\.modelContext) private var context
    
    @State private var showingAddSessionSheet = false
    @State private var showingEditBookSheet = false
    
    var book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Book info
            Text(book.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            HStack {
                Text("\(book.author),")
                Text("\(book.totalPages) pages")
            }
            
            Divider()
            Text("Reading Sessions")
                .font(.headline)
            
            List {
                ForEach(book.sessions) { session in
                    Text("Session on \(session.date, style: .date): \(session.startPage) - \(session.endPage ?? 0)")
                }
            }
        }
        .padding()
        .navigationTitle("Book Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Add Session") { showingAddSessionSheet = true }
                    Button("Edit Book Info") { showingEditBookSheet = true }
                } label: {
                    Label("Options", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditBookSheet) {
            EditBookView(book: book)
        }
    }
}

#Preview {
    BookDetailView(
        book: Book(
            title: "Dune",
            author: "Frank Herbert",
            totalPages: 100
        )
    )
}
