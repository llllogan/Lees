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
    @State private var selectedUIImage: UIImage? = nil
    @State private var showingImagePicker = false
    
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
                
                Button("Select Cover Image") {
                    showingImagePicker = true
                }
            }
            .navigationTitle("Add a New Book")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let totalPages = Int(totalPagesText) ?? 0
                        let imageData = selectedUIImage?.jpegData(compressionQuality: 0.8)
                        let newBook = Book(title: title, author: author, totalPages: totalPages, imageData: imageData)
                        context.insert(newBook)
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

#Preview {
    ContentView()
}
