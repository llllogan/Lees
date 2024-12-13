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
    
    var imageData: Data?
    
    init(title: String, author: String, totalPages: Int, imageData: Data? = nil) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.totalPages = totalPages
        self.imageData = imageData
    }
}
