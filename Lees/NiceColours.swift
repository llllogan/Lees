//
//  NiceGray.swift
//  Lees
//
//  Created by Logan Janssen | Codify on 16/12/2024.
//

import SwiftUI
import SwiftData

extension UIColor {
    static let niceGray = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .light, .unspecified:
            // Darker than before (originally 0.8, now 0.4)
            return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        case .dark:
            // Even darker in dark mode (originally 0.2, now 0.1)
            return UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        @unknown default:
            return UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        }
    }
}

extension UIColor {
    static let niceBackground = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .light, .unspecified:
            return .secondarySystemBackground
        case .dark:
            return .systemBackground
        @unknown default:
            return .secondarySystemBackground
        }
    }
}



extension Color {
    static let progressGreen = Color(red: 0.3, green: 1.0, blue: 0.2)
}



#Preview {
    
    let mockBook = Book(title: "Dune", author: "Frank Herbert", totalPages: 105)
    let mockReadingSession = ReadingSession(date: Date(), startPage: 0, book: mockBook)
    
    let schema = Schema([Book.self, ReadingSession.self])
    let container = try! ModelContainer(for: schema)
    
    container.mainContext.insert(mockBook)
    container.mainContext.insert(mockReadingSession)
    try! container.mainContext.save()
            
    return NavigationStack {
        BookDetailView(book: mockBook)
            .modelContainer(container)
    }
}
