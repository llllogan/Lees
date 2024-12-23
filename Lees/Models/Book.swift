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
    
    var currentPage: Int?
    
    var imageData: Data?
    
    init(title: String, author: String, totalPages: Int, imageData: Data? = nil, currentPage: Int? = nil) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.totalPages = totalPages
        self.imageData = imageData
        self.currentPage = currentPage
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
    
    var progress: Int {
        guard totalPages > 0 else { return 0 }
        guard currentPage != nil else { return 0 }
        
        let doubleValue = Double(self.currentPage!) / Double(self.totalPages)
        
        return Int(doubleValue * 100)
    }
}
