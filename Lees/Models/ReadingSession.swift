//
//  ReadingSession.swift
//  Lees
//
//  Created by Logan Janssen | Codify on 9/12/2024.
//

import SwiftData
import SwiftUI
import Foundation

@Model
class ReadingSession {
    
    var id: UUID
    var date: Date
    var endDate: Date?
    var startPage: Int
    var endPage: Int?
    var book: Book
    
    init(date: Date, startPage: Int, book: Book) {
        self.id = UUID()
        self.date = date
        self.startPage = startPage
        self.book = book
    }
    
    var pagesRead: Int {
        if (endPage == nil) {
            return 0
        } else {
            return max(0, endPage! - startPage + 1)
        }
    }
}
