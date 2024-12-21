//
//  BookDetailView.swift
//  Lees
//
//  Created by Logan Janssen | Codify on 9/12/2024.
//

import SwiftUI
import SwiftData
import Charts

struct BookDetailView: View {
    @Environment(\.modelContext) private var context
    
    let bookId: UUID
    
    @Query var fetchedBooks: [Book]
    @Query var fetchedReadingSessions: [ReadingSession]
    
    // MARK: - State
    @State private var showingEditBookSheet = false
    @State private var showingEndPagePrompt = false
    
    @State private var endPageText = ""
    
    /// The current active session
    @State private var currentSession: ReadingSession?
    
    /// Whether the current session is paused (true) or active (false)
    @State private var pausedSession = true
    
    /// Used to trigger frequent UI updates for our session time display
    @State private var now = Date()
    
    /// Our repeating timer; invalidated when session is stopped
    @State private var timer: Timer? = nil
    
    
    init(book: Book) {
        self.bookId = book.id
        _fetchedBooks = Query(filter: #Predicate<Book> { $0.id == bookId })
        _fetchedReadingSessions = Query(filter: #Predicate<ReadingSession> { $0.book.id == bookId })
    }
    
    private var book: Book {
        fetchedBooks.first!
    }
    
    private var readingSessions: [ReadingSession] {
        fetchedReadingSessions
    }
    
    @State private var uploadedImage: UIImage? = nil
    
    
    
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                topSection
                
                if ((currentSession) != nil) {
                    sectionForCurrentSession
                        .background(Color(UIColor.niceGray))
                        .cornerRadius(16)
                        .padding(.horizontal)
                }
                
                progressDisplay
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.niceGray))
                    .cornerRadius(16)
                    .padding(.horizontal)
                
                Spacer()

                
                readingSessionsSection
                    .padding(.horizontal)
                
            }
        }
        .background(Color(uiColor: .niceBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(
                    action: {},
                    label: {
                        Image(systemName: "ellipsis.circle")
                    }
                )
            }

        }
        .ignoresSafeArea(edges: .top)
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
    
    // MARK: - Top Section
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
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .dynamicForeground(uiImage: uiImageFromData(book.displayedImageData))
                    
                    Text("\(book.author)")
                        .fontWeight(.semibold)
                        .dynamicForeground(uiImage: uiImageFromData(book.displayedImageData))
                }
                
                Spacer()
                Button(action: {
                    currentSession = ReadingSession(
                        date: Date(),
                        startPage: nextSessionStartPage,
                        book: book
                    )
                    
                    pausedSession = false
                    
                    startTimer()
                }) {
                    Text("Start Reading")
                    Image(systemName: "book.fill")
                }
                .font(.subheadline)
                .foregroundColor(Color(uiColor: .label))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(UIColor.niceGray).opacity(0.5))
                .clipShape(Capsule())
            }
            .padding()
        }
    }
    
    
    
    // MARK: - Current Session Section
    private var sectionForCurrentSession: some View {

        HStack {
            VStack(alignment: .leading) {
                Text("Reading Session")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
                Label("\(formattedElapsedTime)", systemImage: "record.circle")
                    .symbolEffect(.pulse.byLayer, options: .repeat(.continuous))
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text("Starting on page \(currentSession?.startPage ?? nextSessionStartPage)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right side: Two buttons (Play/Pause and Stop)
            HStack {
                Button(action: togglePlayPause) {
                    Image(systemName: pausedSession ? "play.fill" : "pause.fill")
                        .frame(width: 44, height: 44)
                        .foregroundColor(.white)
                        .background(Color.secondary)
                        .cornerRadius(8)
                }
                
                Button(action: stopSession) {
                    Image(systemName: "stop.fill")
                        .frame(width: 44, height: 44)
                        .foregroundColor(.white)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
    
    
    // MARK: - Progress Display
    private var progressDisplay: some View {
        
        VStack {
            
            HStack {
                Text("Progress")
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()
                
                Button("show breakdown") {
                    showingEditBookSheet = true
                }
            }
            
            Chart {
                BarMark(
                    xStart: .value("Start", 0),
                    xEnd:   .value("End", 100),
                    y:      .value("Category", "progress")
                )
                .foregroundStyle(Color.black.opacity(0.1))
                .cornerRadius(6)
                
                BarMark(
                    xStart: .value("Start", 0),
                    xEnd:   .value("End", book.progress),
                    y:      .value("Category", "progress")
                )
                .foregroundStyle(Color.progressGreen)
                .cornerRadius(6)
            }
            .chartXScale(domain: 0...100)
            .chartYAxis(Visibility.hidden)
            .frame(maxHeight: 35)
        }
    }
    
    
    
    private var readingSessionsSection: some View {
        
        Section {
            Text("Reading Sessions")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(readingSessions) { session in
                let message: String = session.endPage == nil ? "Reading..." : "\(session.startPage) - \(session.endPage!)"
                Text("\(session.date, style: .date): \(message)")
            }
        }
    }
    
    
    // MARK: - Helpers
    
    
    private var nextSessionStartPage: Int {
        let maxEndPage = readingSessions.compactMap { $0.endPage }.max() ?? 0
        return maxEndPage + 1
    }
    
    
    private var formattedElapsedTime: String {
        guard let session = currentSession else {
            return "00:00.000"
        }
        // Use 'now' to compute a live difference
        let diff = now.timeIntervalSince(session.date)
        let minutes = Int(diff) / 60
        let seconds = Int(diff) % 60
        let milliseconds = Int((diff - floor(diff)) * 1000)
        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }
    
    // MARK: - Helpers
    
    /// Indicates if a session is active (not paused)
    private var isSessionActive: Bool {
        !pausedSession && currentSession != nil
    }
    
    private func startTimer() {
        // Clear any old timer
        timer?.invalidate()
        
        // Fire approximately every 0.1 seconds for smooth time display
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // Only update 'now' if not paused
            guard !pausedSession else { return }
            now = Date()
        }
    }
    
    /// Toggles between paused and unpaused states
    private func togglePlayPause() {
        pausedSession.toggle()
        // If unpausing, ensure timer is running
        if !pausedSession {
            startTimer()
        }
    }
    
    /// Stop session entirely, prompting user for end page
    private func stopSession() {
        // If there's a current session, user must enter an end page
        if currentSession != nil {
            showingEndPagePrompt = true
        }
    }
    
    /// Finalizes the current session by setting an endPage, saving it to the model, etc.
    private func finalizeSession() {
        guard let currentSession else { return }
        
        // Attempt to parse user input
        let endingPage = Int(endPageText) ?? currentSession.startPage
        
        // Stop the timer
        timer?.invalidate()
        timer = nil
        pausedSession = true
        
        // Update the session’s end page
        currentSession.endPage = endingPage
        do {
            try context.save()
        } catch {
            print("Failed to save endPage: \(error)")
        }
        
        // Clear the session & prompt
        self.currentSession = nil
        self.endPageText = ""
        self.showingEndPagePrompt = false
    }
    
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
