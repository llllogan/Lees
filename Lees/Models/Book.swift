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
    var currentPage: Int
    
    var imageData: Data?
    
    init(title: String, author: String, totalPages: Int, currentPage: Int = 0 , imageData: Data? = nil) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.imageData = imageData
    }
    
    var displayedImageData: Data {
        if let data = imageData {
            return data
        } else {
            // Attempt to load the default "DuneCover" image and convert it to Data
            if let defaultImage = UIImage(named: "DuneCover"),
               let defaultData = defaultImage.jpegData(compressionQuality: 1.0) {
                return defaultData
            }
            // If the default image fails to load for some reason, return empty Data
            return Data()
        }
    }
    
    var progress: Double {
        let totalPages = Double(self.totalPages)
        let currentPage = Double(self.currentPage)
        return currentPage / totalPages
    }
}
