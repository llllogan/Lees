//
//  AddReadingSessionView.swift
//  Lees
//
//  Created by Logan Janssen | Codify on 9/12/2024.
//

import SwiftUI
import SwiftData

struct AddReadingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    var book: Book
    @State private var startPageText = ""
    @State private var endPageText = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                TextField("Start Page", text: $startPageText)
                    .keyboardType(.numberPad)
                TextField("End Page", text: $endPageText)
                    .keyboardType(.numberPad)
            }
            .navigationTitle("New Reading Session")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard let startPage = Int(startPageText),
                              let endPage = Int(endPageText) else { return }
                        
                        let session = ReadingSession(date: date, startPage: startPage, endPage: endPage, book: book)
                        context.insert(session)
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
