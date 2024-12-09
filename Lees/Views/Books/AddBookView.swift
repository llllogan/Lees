//
//  AddBookView.swift
//  Lees
//
//  Created by Logan Janssen | Codify on 9/12/2024.
//

import SwiftUI
import SwiftData

struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var title = ""
    @State private var author = ""
    @State private var totalPagesText = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Author", text: $author)
                TextField("Total Pages", text: $totalPagesText)
                    .keyboardType(.numberPad)
            }
            .navigationTitle("Add a New Book")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let totalPages = Int(totalPagesText) ?? 0
                        let newBook = Book(title: title, author: author, totalPages: totalPages)
                        context.insert(newBook)
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
