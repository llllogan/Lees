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
    }
}

struct BookGridItemView: View {
    
    let book: Book
    
    var body: some View {
        
        ZStack {
            // If you want to compute a background color from the image:
            if let uiImage = uiImageFromData(book.imageData),
               let averageColor = uiImage.averageColor {
                Color(averageColor)
                    .ignoresSafeArea()
            } else {
                // Fallback color if no image or color extraction fails
                Color.gray.opacity(0.2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if let uiImage = uiImageFromData(book.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .cornerRadius(8)
                } else {
                    // Placeholder image if none
                    Image(systemName: "book.closed")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                Text(book.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical)
        }
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

private func uiImageFromData(_ data: Data?) -> UIImage? {
    guard let data = data else { return nil }
    return UIImage(data: data)
}

extension UIImage {
    var averageColor: UIColor? {
        guard let cgImage = self.cgImage else { return nil }

        let inputImage = CIImage(cgImage: cgImage)
        let extent = inputImage.extent

        // The CIAreaAverage filter returns the average color of the specified region.
        guard let filter = CIFilter(name: "CIAreaAverage") else { return nil }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
        
        // Create a CIContext to render the output
        let context = CIContext(options: nil)
        guard let outputImage = filter.outputImage else { return nil }

        // Render the output into a 1x1 bitmap
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: CGColorSpaceCreateDeviceRGB())

        // Convert the RGBA values to a UIColor
        return UIColor(
            red: CGFloat(bitmap[0]) / 255.0,
            green: CGFloat(bitmap[1]) / 255.0,
            blue: CGFloat(bitmap[2]) / 255.0,
            alpha: CGFloat(bitmap[3]) / 255.0
        )
    }
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
