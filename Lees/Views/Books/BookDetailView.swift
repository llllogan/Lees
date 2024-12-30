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
    
    @Query private var allReadingSessions: [ReadingSession]
    @State private var currentSession: ReadingSession?
    
    @State private var showingEditBookSheet = false
    @State private var showingEndPagePrompt = false
    @State private var showingDeleteConfirmation = false
    @State private var showDetailedChart = false
    
    @State private var pausedSession = true
    @State private var hasStartedSession = false
    
    @State private var endPageText = ""
    @State private var now = Date()
    
    @State private var readingSessionToEdit: ReadingSession? = nil
    @State private var uploadedImage: UIImage? = nil
    @State private var timer: Timer? = nil
    
    @State private var resetSwipeRowOffsets: Bool = false
    
    
    private var autoStartReadingSession: Bool = false
    
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
    
    private var bookProgress: Int {
        guard let mostRecentSession = readingSessions.sorted(by: { $0.date > $1.date }).first,
              book.totalPages > 0
        else {
            return 0
        }
        
        let currentPage = mostRecentSession.endPage ?? mostRecentSession.startPage
        let fractionComplete = Double(currentPage) / Double(book.totalPages)
        
        return min(100, Int((fractionComplete * 100).rounded()))
    }
    
    
    
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
        .sheet(item: $readingSessionToEdit) { session in
            EditReadingSessionView(session: session, onComplete: {
                resetSwipeRowOffsets = true
            })
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
                Text("From page \(currentSession?.startPage ?? nextSessionStartPage)")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Label {
                    Text(formattedElapsedTime)
                        .contentTransition(.numericText())
                        .animation(.default, value: formattedElapsedTime)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "record.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .symbolEffect(.pulse.byLayer, options: .repeat(.continuous))
                }
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
                    Image(systemName: showDetailedChart ? "align.vertical.bottom.fill" : "align.vertical.bottom")
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
                xEnd:   .value("End", bookProgress),
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
            ForEach(readingSessions) { session in
                LineMark(
                    x: .value("Start Date", session.date, unit: .minute),
                    y: .value("End Page", session.endPage ?? session.startPage)
                )
                .foregroundStyle(Color.progressGreen)
                .interpolationMethod(.linear)
                .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
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
            }
            VStack {
                ForEach(groupedReadingSessions, id: \.date) { group in
                    VStack(alignment: .leading, spacing: 0) {
                        
                        VStack(alignment: .leading) {
                            Text(group.date, style: .date)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(pagesRead(for: group)) pages read")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.top)
                        .padding(.bottom, 4)
                        
                        VStack(spacing: 0) {
                            ForEach(group.sessions) { session in
                                
                                SwipeableRow (
                                    resetOffset: $resetSwipeRowOffsets,
                                    content: {
                                        HStack {
                                            Text(session.date, style: .time)
                                                .font(.headline)
                                            Spacer()
                                            Text("\(session.startPage) - \(session.endPage ?? session.startPage)")
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(12)
                                        .background(Color(UIColor.niceGray))
                                    }, leadingActions: {
                                        Button {
                                            readingSessionToEdit = session
                                        } label: {
                                            HStack {
                                                Image(systemName: "pencil")
                                                Text("Edit")
                                            }
                                            .foregroundColor(.white)
                                        }
                                    }, trailingActions: {
                                        Button {
                                            deleteReadingSession(session)
                                        } label: {
                                            HStack {
                                                Image(systemName: "trash")
                                                Text("Delete")
                                            }
                                            .foregroundColor(.white)
                                        }
                                    }
                                )
                                
                                if session != group.sessions.last {
                                    Divider()
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
    
    // MARK: - Edit Reading Session Sheet
    struct EditReadingSessionView: View {
        @Environment(\.dismiss) private var dismiss
        
        @Bindable var session: ReadingSession
        
        var onComplete: () -> Void = { }
        
        private var endDateBinding: Binding<Date> {
            Binding<Date>(
                get: {
                    session.endDate ?? session.date
                },
                set: { newValue in
                    session.endDate = newValue
                }
            )
        }
        
        var body: some View {
            NavigationStack {
                Form {
                    Section(header: Text("Pages")) {
                        HStack {
                            Text("Start Page")
                            Spacer()
                            TextField("Start Page",
                                      value: $session.startPage,
                                      format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                        }
                        
                        HStack {
                            Text("End Page")
                            Spacer()
                            TextField("End Page",
                                      value: $session.endPage,
                                      format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                        }
                    }
                    
                    Section(header: Text("Dates")) {
                        DatePicker("Start Date",
                                   selection: $session.date,
                                   displayedComponents: [.date, .hourAndMinute])
                        
                        DatePicker("End Date",
                                   selection: endDateBinding,
                                   displayedComponents: [.date, .hourAndMinute])
                    }
                }
                .navigationTitle("Edit Session")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                            onComplete()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            dismiss()
                            onComplete()
                        }
                    }
                }
            }
        }
    }
    
    
    // MARK: - Helpers
    
    private func deleteReadingSession(_ session: ReadingSession) {
        context.delete(session)
        do {
            try context.save()
        } catch {
            print("Failed to delete session: \(error)")
        }
    }
    
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
    
    
    private func pagesRead(for group: (date: Date, sessions: [ReadingSession])) -> Int {
        guard !group.sessions.isEmpty else { return 0 }
        
        let earliestSession = group.sessions.last
        let latestSession   = group.sessions.first
        
        let startPage = earliestSession?.startPage ?? 0
        let endPage   = (latestSession?.endPage ?? latestSession?.startPage) ?? 0
        let total     = endPage - startPage
        
        return max(0, total)
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
