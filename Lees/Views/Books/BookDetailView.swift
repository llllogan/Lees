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
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var book: Book
    
    var autoStartReadingSession: Bool = false
    
    @Query private var allReadingSessions: [ReadingSession]
    
    private var readingSessions: [ReadingSession] {
        allReadingSessions.filter { $0.book.id == book.id }
    }
    
    private var groupedReadingSessions: [(date: Date, sessions: [ReadingSession])] {
        
        let grouped = Dictionary(grouping: readingSessions) { session in
            Calendar.current.startOfDay(for: session.date)
        }
        
        return grouped
            .map { (key, value) in
                (date: key, sessions: value.sorted { $0.date > $1.date })
            }
            .sorted(by: { $0.date > $1.date })
    }
    
    
    @State private var showingEditBookSheet = false
    @State private var showingEndPagePrompt = false
    
    @State private var endPageText = ""
    
    @State private var currentSession: ReadingSession?
    @State private var pausedSession = true
    @State private var now = Date()
    @State private var timer: Timer? = nil
    
    @State private var uploadedImage: UIImage? = nil
    
    @State private var showingDeleteConfirmation = false
    
    @State private var hasStartedSession = false
    
    @State private var showDetailedChart = false
    
    
    // MARK: - Init
    init(book: Book, autoStartReadingSession: Bool = false) {
        self.book = book
        self.autoStartReadingSession = autoStartReadingSession
    }
    
    
    // MARK: - Main View
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                topSection
                
                if ((currentSession) != nil) {
                    sectionForCurrentSession
                        .background(Color(UIColor.niceGray))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .transition(.opacity)
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
        .animation(.default, value: currentSession)
        .onAppear {
            if autoStartReadingSession, !hasStartedSession {
                startReadingSession()
                hasStartedSession = true
            }
        }
        .background(Color(uiColor: .niceBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit Book") {
                        showingEditBookSheet = true
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Text("Delete Book")
                    }

                } label: {
                    Image(systemName: "ellipsis.circle")
                }
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
        .alert("Delete Book?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteBook()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this book?")
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
                    
                    Text(book.author)
                        .fontWeight(.semibold)
                        .dynamicForeground(uiImage: uiImageFromData(book.displayedImageData))
                }
                
                Spacer()
                Button(action: {
                    guard !isSessionActive else { return }
                    startReadingSession()
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
                Label {
                    Text(formattedElapsedTime)
                        .contentTransition(.numericText())
                        .animation(.default, value: formattedElapsedTime)
                        .font(.title3)
                        .fontWeight(.bold)
                } icon: {
                    Image(systemName: "record.circle")
                        // .symbolEffect(.pulse.byLayer, options: .repeat(.continuous))
                }
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
                
                Button(action: {
                    withAnimation {
                        showDetailedChart.toggle()
                    }
                }) {
                    Image(systemName: showDetailedChart ? "eye" : "eye.slash")
                    Text("Breakdown")
                        .font(.subheadline)
                }
            }
            
            if (showDetailedChart) {
                progressChartDetail
                    .transition(.identity)
            } else {
                progressChart
                    .transition(.identity)
            }
             
            
        }
    }
    
    private var progressChart: some View {
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
    
    
    private var progressChartDetail: some View {
        Chart {
            if let firstDate = readingSessions.first?.date {
                LineMark(
                    x: .value("Start Date", firstDate),
                    y: .value("End Page", 0)
                )
                .foregroundStyle(Color.progressGreen)
                .interpolationMethod(.catmullRom)
            }
            ForEach(readingSessions) { session in
                LineMark(
                    x: .value(
                        "Start Date",
                        session.date,
                        unit: .minute
                    ),
                    y: .value("End Page", session.endPage ?? session.startPage)
                )
                .foregroundStyle(Color.progressGreen)
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom, values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisValueLabel() {
                    if let dateValue = value.as(Date.self) {
                        Text(dateValue, format: .dateTime.weekday(.abbreviated))
                            .foregroundColor(.secondary)
                    } else {
                        Text("")
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic) {
                AxisValueLabel()
            }
        }
        .frame(maxHeight: 200)
    }
    
    
    // MARK: - Reading Sessions
    private var readingSessionsSection: some View {
        
        VStack {
            HStack {
                Text("Reading Sessions")
                    .font(.callout)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    
                }){
                    Text("View More")
                        .font(.subheadline)
                }
            }
            VStack {
                ForEach(groupedReadingSessions, id: \.date) { group in
                    VStack(alignment: .leading, spacing: 0) {
                        
                        ForEach(group.sessions) { session in
                            
                            List {
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading) {
                                        if session == group.sessions.first {
                                            Text(group.date, style: .date)
                                                .font(.subheadline)

                                        }
                                        Text(session.date, style: .time)
                                            .font(.headline)
                                    }
                                    Spacer()
                                    Text("\(session.startPage) - \(session.endPage ?? session.startPage)")
                                        .foregroundColor(.secondary)
                                }
                                .swipeActions {
                                    Button("Edit") {
                                        // Trigger the sheet to edit the session
                                    }
                                    .tint(.blue)

                                    Button("Delete", role: .destructive) {
                                        // Handle deletion
                                    }
                                }
                            }
                        }
                    }
                    .background(Color(UIColor.niceGray))
                    .cornerRadius(12)
                }
            }
        }
    }
    // MARK: - Helpers
    
    
    private func startReadingSession() {
        currentSession = ReadingSession(
            date: Date(),
            startPage: nextSessionStartPage,
            book: book
        )
        
        print(currentSession!.startPage)
        
        pausedSession = false
        
        startTimer()
    }
    
    
    private func deleteBook() {
        context.delete(book)
        do {
            try context.save()
            dismiss()
        } catch {
            print("Failed to delete book: \(error)")
        }
    }
    
    
    private var nextSessionStartPage: Int {
        let maxEndPage = readingSessions.compactMap { $0.endPage }.max() ?? 0
        return maxEndPage
    }
    
    
    private var formattedElapsedTime: String {
        guard let session = currentSession else {
            return "00:00.000"
        }
        // Use 'now' to compute a live difference
        let diff = now.timeIntervalSince(session.date)
        let minutes = Int(diff) / 60
        let seconds = Int(diff) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
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
        
        let endingPage = Int(endPageText) ?? currentSession.startPage
        book.currentPage = endingPage
        
        currentSession.endPage = endingPage
        currentSession.endDate = Date()
        
        context.insert(currentSession)
        
        do {
            try context.save()  // Force a save if you want changes persisted immediately
        } catch {
            print("Failed to save session: \(error)")
        }
        
        timer?.invalidate()
        timer = nil
        pausedSession = true
        self.currentSession = nil
        self.endPageText = ""
        self.showingEndPagePrompt = false
    }
    
}


#Preview {
    
    let mockBook = Book(title: "Dune", author: "Frank Herbert", totalPages: 105)
    let mockReadingSession = ReadingSession(date: Date(), startPage: 0, book: mockBook)
    let mockReadingSession2 = ReadingSession(date: Date(), startPage: 10, book: mockBook)
    
    let schema = Schema([Book.self, ReadingSession.self])
    let container = try! ModelContainer(for: schema)
    
    container.mainContext.insert(mockBook)
    container.mainContext.insert(mockReadingSession)
    container.mainContext.insert(mockReadingSession2)
    try! container.mainContext.save()
            
    return NavigationStack {
        BookDetailView(book: mockBook)
            .modelContainer(container)
    }
}
