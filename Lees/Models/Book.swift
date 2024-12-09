//
//  Book.swift
//  Lees
//
//  Created by Logan Janssen | Codify on 9/12/2024.
//

import SwiftUI
import SwiftData

@Model
class Book {
    var id: UUID
    var title: String
    var author: String
    var totalPages: Int
    
    // A book can have multiple reading sessions
    var sessions: [ReadingSession]
    
    init(title: String, author: String, totalPages: Int) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.totalPages = totalPages
        self.sessions = []
    }
}
