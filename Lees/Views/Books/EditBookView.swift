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
    @State private var selectedUIImage: UIImage?
    @State private var showingImagePicker = false
    
    init(book: Book) {
        self.book = book
        _title = State(initialValue: book.title)
        _author = State(initialValue: book.author)
        _totalPagesText = State(initialValue: "\(book.totalPages)")
        if let data = book.imageData, let uiImage = UIImage(data: data) {
            _selectedUIImage = State(initialValue: uiImage)
        } else {
            _selectedUIImage = State(initialValue: nil)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Author", text: $author)
                TextField("Total Pages", text: $totalPagesText)
                    .keyboardType(.numberPad)
                if let uiImage = selectedUIImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .cornerRadius(8)
                }
                
                Button("Change Cover Image") {
                    showingImagePicker = true
                }
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
                        if let uiImage = selectedUIImage {
                            book.imageData = uiImage.jpegData(compressionQuality: 0.8)
                        }
                        try? context.save()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedUIImage)
            }
        }
    }
}
