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
    @Query private var allReadingSessions: [ReadingSession]

    @State private var showingAddBookSheet = false
    
    @State private var selectedBookForEditing: Book?
    @State private var showingEditBookSheet = false
    
    @State private var showingDeleteConfirmation = false
    @State private var bookToDelete: Book? = nil
    

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
                            BookGridItemView(book: book, allReadingSessions: allReadingSessions)
                        }
                        .contextMenu {
                            Button("Edit Book") {
                                selectedBookForEditing = book
                                showingEditBookSheet = true
                            }

                            Button(role: .destructive) {
                                bookToDelete = book
                                showingDeleteConfirmation = true
                            } label: {
                                Text("Delete Book")
                            }
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
        .sheet(isPresented: $showingEditBookSheet) {
            if let bookToEdit = selectedBookForEditing {
                EditBookView(book: bookToEdit)
            }
        }
        .alert("Delete Book?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let book = bookToDelete {
                    deleteBook(book)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let book = bookToDelete {
                Text("Are you sure you want to delete “\(book.title)”?")
            } else {
                Text("Are you sure you want to delete this book?")
            }
        }
        .background(Color(uiColor: .niceBackground))
    }
    
    private func deleteBook(_ book: Book) {
        context.delete(book)
        do {
            try context.save()
        } catch {
            print("Failed to delete book: \(error)")
        }
    }
}

struct BookGridItemView: View {
    
    let book: Book
    let allReadingSessions: [ReadingSession]
    
    private var readingSessions: [ReadingSession] {
        allReadingSessions.filter { $0.book.id == book.id }
    }
    
    private var bookCurrentPage: Int {
        guard let mostRecentSession = readingSessions.sorted(by: { $0.date > $1.date }).first else {
            return 0
        }
        
        return mostRecentSession.endPage ?? mostRecentSession.startPage
    }
    
    private var bookProgress: Int {
        guard let mostRecentSession = readingSessions.sorted(by: { $0.date > $1.date }).first,
              book.totalPages > 0
        else {
            return 0
        }
        
        let currentPage = mostRecentSession.endPage ?? mostRecentSession.startPage
        let fractionComplete = Double(currentPage) / Double(book.totalPages)
        
        return min(100, Int((fractionComplete * 100).rounded()))
    }



    
    var body: some View {
        
        @State var navigateToDetail = false
            
        VStack(alignment: .leading, spacing: 8) {
            
            Text(book.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Text(book.author)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Label("\(bookCurrentPage)", systemImage: "book.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            Label("\(bookProgress)%", systemImage: "flag.pattern.checkered")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            NavigationLink(
                destination: {
                    BookDetailView(book: book, autoStartReadingSession: true)
                },
                label: {
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
                        .dynamicForeground(uiImage: uiImageFromData(book.displayedImageData))
                }
            )
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
    
    let mockBook = Book(title: "Dunee onib onj", author: "Frank Herbert", totalPages: 105)
    
    let schema = Schema([Book.self, ReadingSession.self])
    let container = try! ModelContainer(for: schema)
    
    container.mainContext.insert(mockBook)
    try! container.mainContext.save()
            
    return ContentView()
        .modelContainer(container)
}
