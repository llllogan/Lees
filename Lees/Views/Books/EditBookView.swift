//
//  EditBookView.swift
//  Lees
//
//  Created by Logan Janssen | Codify on 9/12/2024.
//

import SwiftUI
import SwiftData

struct EditBookView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    var book: Book
    @State private var title: String
    @State private var author: String
    @State private var totalPagesText: String
    
    init(book: Book) {
        self.book = book
        _title = State(initialValue: book.title)
        _author = State(initialValue: book.author)
        _totalPagesText = State(initialValue: "\(book.totalPages)")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Author", text: $author)
                TextField("Total Pages", text: $totalPagesText)
                    .keyboardType(.numberPad)
            }
            .navigationTitle("Edit Book")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let totalPages = Int(totalPagesText) ?? book.totalPages
                        book.title = title
                        book.author = author
                        book.totalPages = totalPages
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
