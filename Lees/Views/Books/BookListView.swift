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
    @Query private var books: [Book]

    @State private var showingAddBookSheet = false

    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(books) { book in
                        NavigationLink(value: book) {
                            BookGridItemView(book: book)
                        }
                    }
                }
                .padding()
            }
            .navigationDestination(for: Book.self) { book in
                BookDetailView(book: book)
            }
            .navigationTitle("My Books")
        }
        .navigationTitle("My Books")
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
        .background(Color(uiColor: .niceBackground))
    }
}

struct BookGridItemView: View {
    
    let book: Book
    
    var body: some View {
            
        VStack(alignment: .leading, spacing: 8) {
            
            Text(book.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(book.author)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Label("205", systemImage: "book.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            Label("34%", systemImage: "flag.pattern.checkered")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {}) {
                Text("Start Reading")
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 40)
                    .background {
                        // Create the background image inside the button
                        if let uiImage = uiImageFromData(book.imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .blur(radius: 20) // adjust blur as desired
                                .clipped()
                        } else {
                            Image("DuneCover")
                                .resizable()
                                .scaledToFill()
                                .blur(radius: 20) // adjust blur as desired
                                .clipped()
                        }
                    }
                    .cornerRadius(12)
            }
            .dynamicForeground(uiImage: uiImageFromData(book.displayedImageData))
        }
        .padding()
        .background(Color(UIColor.niceGray))
        .cornerRadius(12)
    }
}



func uiImageFromData(_ data: Data?) -> UIImage? {
    guard let data = data else { return nil }
    return UIImage(data: data)
}


#Preview {
    
    let mockBook = Book(title: "Dune", author: "Frank Herbert", totalPages: 105)
    
    let schema = Schema([Book.self, ReadingSession.self])
    let container = try! ModelContainer(for: schema)
    
    container.mainContext.insert(mockBook)
    try! container.mainContext.save()
            
    return ContentView()
        .modelContainer(container)
}
