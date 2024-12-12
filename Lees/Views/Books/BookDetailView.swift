//
//  BookDetailView.swift
//  Lees
//
//  Created by Logan Janssen | Codify on 9/12/2024.
//

import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Environment(\.modelContext) private var context
    
    @State private var showingEditBookSheet = false
    @State private var currentSession: ReadingSession?
    @State private var isSessionActive = false // Tracks if play/pause state
    @State private var showingEndPagePrompt = false
    @State private var endPageText = ""
    @State private var elapsedTime: TimeInterval = 0 // In seconds, update with a timer
    @State private var timer: Timer? = nil
    
    @State private var uploadedImage: UIImage? = nil
    
    @State var book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            topSection
            
            Section {
                sectionForCurrentSession
                
                Divider()
                
                Text("Reading Sessions")
                    .font(.headline)
                
                List {
                    ForEach(book.sessions) { session in
                        Text("Session on \(session.date, style: .date): \(session.startPage) - \(session.endPage ?? 0)")
                    }
                }
            }
            .padding(.horizontal)
            
        }
        .ignoresSafeArea(edges: .top)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit Book Info") { showingEditBookSheet = true }
                } label: {
                    Label("Options", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditBookSheet) {
            EditBookView(book: book)
        }
        .sheet(isPresented: $showingEndPagePrompt) {
            NavigationStack {
                Form {
                    TextField("Ending Page", text: $endPageText)
                        .keyboardType(.numberPad)
                }
                .navigationTitle("Finish Reading Session")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showingEndPagePrompt = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            finalizeSession()
                        }
                    }
                }
            }
        }
    }
    
    
    private var sectionForCurrentSession: some View {
        Section {
            HStack {
                // Left side: Session info texts
                VStack(alignment: .leading) {
                    Text("Reading session time: \(formattedElapsedTime)")
                        .font(.headline)
                    Text("Starting on page \(currentSession?.startPage ?? nextSessionStartPage)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Right side: Two buttons (Play/Pause and Stop)
                HStack {
                    // Play/Pause button
                    Button(action: togglePlayPause) {
                        Image(systemName: isSessionActive ? "pause.fill" : "play.fill")
                            .frame(width: 44, height: 44)
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    
                    // Stop button
                    Button(action: stopSession) {
                        Image(systemName: "stop.fill")
                            .frame(width: 44, height: 44)
                            .foregroundColor(.white)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    
    private var topSection: some View {
        ZStack(alignment: .bottomLeading) {
            
            if let data = book.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: 400, alignment: .top)
                    .clipped()
            } else {
                // Fallback image from assets
                Image("DuneCover")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: 400, alignment: .top)
                    .clipped()
            }
            
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(uiColor: .systemBackground).opacity(0.8), location: 0.0),
                    .init(color: Color(uiColor: .systemBackground).opacity(0), location: 0.4)
                ]),
                startPoint: .bottom,
                endPoint: .top            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(uiColor: .label))
                    
                    HStack {
                        Text("\(book.author),")
                            .foregroundColor(Color(uiColor: .label))
                        Text("\(book.totalPages) pages")
                            .foregroundColor(Color(uiColor: .label))
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showingEditBookSheet = true
                }) {
                    Text("Edit")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.5))
                        .clipShape(Capsule())
                }
            }
            .padding()
        }
    }
    
    private var nextSessionStartPage: Int {
        // Find the highest end page from existing sessions
        let maxEndPage = book.sessions.compactMap { $0.endPage }.max() ?? 0
        return maxEndPage + 1
    }
    
    private var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let milliseconds = Int((elapsedTime - floor(elapsedTime)) * 1000)
        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }
    
    private func togglePlayPause() {
        if currentSession == nil {
            // Start a new session
            startReadingSession()
        } else {
            // Toggle pause
            isSessionActive.toggle()
            if isSessionActive {
                startTimer()
            } else {
                stopTimer()
            }
        }
    }
    
    private func stopSession() {
        guard currentSession != nil else { return }
        // Prompt user for ending page
        endPageText = ""
        showingEndPagePrompt = true
    }
    
    private func finalizeSession() {
        defer { showingEndPagePrompt = false }
        guard let session = currentSession,
              let endPage = Int(endPageText), endPage >= session.startPage else {
            return
        }
        
        // Update session with endPage and endDate
        session.endPage = endPage
        session.endDate = Date()
        
        // Save changes
        do {
            stopTimer()
            currentSession = nil
            isSessionActive = false
            try context.save()
        } catch {
            print("Error saving ended session: \(error)")
        }
    }
    
    private func startReadingSession() {
        let newStartPage = nextSessionStartPage
        let newSession = ReadingSession(
            date: Date(),
            startPage: newStartPage,
            book: book
        )
        print(book.self)
        
        context.insert(newSession)
        do {
            try context.save()
            currentSession = newSession
            isSessionActive = true
            startTimer()
        } catch {
            print("Error saving new session: \(error)")
        }
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            elapsedTime += 0.01
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    NavigationStack {
        BookDetailView(
            book: Book(
                title: "Dune",
                author: "Frank Herbert",
                totalPages: 100
            )
        )
    }
}
