import SwiftUI
import MapKit
import UserNotifications

// Event detail venue map zoom — higher = zoomed out (e.g. 0.01 tight, 0.015 wider, 0.02 much wider)
private let eventDetailMapSpanDelta = 0.01

struct EventDetailView: View {
    let event: RAEvent
    // Add parameters to support event cycling
    let allEvents: [RAEvent]
    let currentIndex: Int
    var onEventChange: ((RAEvent) -> Void)?
    
    @State private var mapRegion: MKCoordinateRegion
    @State private var mapCameraPosition: MapCameraPosition
    @Environment(\.colorScheme) private var colorScheme
    @State private var showNotificationDialog = false
    @State private var selectedNotificationTime: NotificationTimeOption = .oneHour
    @State private var hasActiveNotification = false
    @State private var currentEvent: RAEvent // Track the current event for map updates
    
    // Animation states
    @State private var dragOffset = CGFloat.zero
    @State private var currentPage: Int // Track the current page index
    @State private var offset: CGFloat = 0
    @State private var isHorizontalSwiping = false // Track if currently swiping horizontally
    
    @StateObject private var genreBeatController = GenreBeatController()
    @ObservedObject private var mapSettings = MapSettings.shared
    
    // Minimum drag amount required to trigger a change
    private let dragThreshold: CGFloat = 50
    
    init(event: RAEvent, allEvents: [RAEvent] = [], currentIndex: Int = 0, onEventChange: ((RAEvent) -> Void)? = nil) {
        self.event = event
        self.allEvents = allEvents
        self.currentIndex = currentIndex
        self.onEventChange = onEventChange
        self._currentEvent = State(initialValue: event)
        self._currentPage = State(initialValue: currentIndex)
        
        // Initialize map region
        if let venue = event.venue, let location = venue.location {
            let initialCoordinate = CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )
            _mapRegion = State(initialValue: MKCoordinateRegion(
                center: initialCoordinate,
                span: MKCoordinateSpan(latitudeDelta: eventDetailMapSpanDelta, longitudeDelta: eventDetailMapSpanDelta)
            ))
            _mapCameraPosition = State(initialValue: .region(MKCoordinateRegion(
                center: initialCoordinate,
                span: MKCoordinateSpan(latitudeDelta: eventDetailMapSpanDelta, longitudeDelta: eventDetailMapSpanDelta)
            )))
        } else {
            // Default to a generic region if no venue location
            let defaultCoordinate = CLLocationCoordinate2D(latitude: 51.5074, longitude: 0.1278) // London
            _mapRegion = State(initialValue: MKCoordinateRegion(
                center: defaultCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
            _mapCameraPosition = State(initialValue: .region(MKCoordinateRegion(
                center: defaultCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )))
        }
    }
    
    // Get the adjacent events for the carousel
    private func getPageContent() -> [RAEvent] {
        if allEvents.isEmpty || allEvents.count == 1 {
            return [currentEvent]
        }
        
        let previous = getPreviousEvent()
        let next = getNextEvent()
        
        return [previous, currentEvent, next]
    }
    
    private func getPreviousEvent() -> RAEvent {
        let previousIndex = (currentPage - 1 + allEvents.count) % allEvents.count
        return allEvents[previousIndex]
    }
    
    private func getNextEvent() -> RAEvent {
        let nextIndex = (currentPage + 1) % allEvents.count
        return allEvents[nextIndex]
    }
    
    private var isSinglePageCarousel: Bool {
        allEvents.isEmpty || allEvents.count == 1
    }
    
    // Calculate progress during drag (0 means no drag, +1/-1 means full drag)
    private var swipeProgress: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return dragOffset / screenWidth
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Neo-punk background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Create a custom carousel
                HStack(spacing: 0) {
                    ForEach(getPageContent()) { event in
                        ScrollView {
                            EventContentView(
                                event: event,
                                mapRegion: $mapRegion,
                                mapCameraPosition: $mapCameraPosition,
                                showNotificationDialog: $showNotificationDialog,
                                hasActiveNotification: $hasActiveNotification,
                                genreBeatController: genreBeatController,
                                isCurrentEvent: event.id == currentEvent.id,
                                genreHapticsEnabled: mapSettings.genreHapticsEnabled
                            )
                        }
                        .frame(width: geometry.size.width)
                        .scrollDisabled(isHorizontalSwiping) // Lock scrolling when swiping horizontally
                    }
                }
                .frame(width: geometry.size.width, alignment: .leading)
                .offset(x: (isSinglePageCarousel ? 0 : -geometry.size.width) + offset + dragOffset)
                
                // Swipe indicators for visual feedback
                if !isSinglePageCarousel {
                HStack(spacing: 0) {
                    // Left indicator
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.pink.opacity(0.8), Color.clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 50)
                        .opacity(swipeProgress > 0 ? min(swipeProgress * 1.5, 0.8) : 0)
                    
                    Spacer()
                    
                    // Right indicator
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.pink.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 50)
                        .opacity(swipeProgress < 0 ? min(-swipeProgress * 1.5, 0.8) : 0)
                }
                .edgesIgnoringSafeArea(.horizontal)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showNotificationDialog) {
            NotificationOptionsView(
                event: currentEvent,
                selectedTime: $selectedNotificationTime,
                isPresented: $showNotificationDialog,
                hasActiveNotification: $hasActiveNotification
            )
        }
        .onAppear {
            checkNotificationStatus()
            startGenreBeat(for: currentEvent)
        }
        .onDisappear {
            genreBeatController.stop()
        }
        .onChange(of: currentEvent.id) { _, _ in
            startGenreBeat(for: currentEvent)
        }
        .onChange(of: mapSettings.genreHapticsEnabled) { _, _ in
            startGenreBeat(for: currentEvent)
        }
        // Add gesture recognizer
        .gesture(
            DragGesture(minimumDistance: 10, coordinateSpace: .global)
                .onChanged { value in
                    guard allEvents.count > 1 else { return }
                    // Check if the drag is primarily horizontal
                    if abs(value.translation.width) > abs(value.translation.height) * 1.5 {
                        dragOffset = value.translation.width
                        
                        // Lock vertical scrolling when horizontal swipe detected
                        if !isHorizontalSwiping && abs(value.translation.width) > 20 {
                            isHorizontalSwiping = true
                        }
                    }
                }
                .onEnded { value in
                    guard allEvents.count > 1 else { return }
                    // Calculate final offset and update page if needed
                    let predictedEndTranslation = value.predictedEndTranslation.width
                    let screenWidth = UIScreen.main.bounds.width
                    
                    // Determine if the drag was significant enough to trigger a page change
                    if predictedEndTranslation > screenWidth / 3 && allEvents.count > 1 {
                        // Swipe right - go to previous
                        // Start animation from current position (don't reset dragOffset yet)
                        let finalOffset = screenWidth
                        withAnimation(.easeInOut(duration: 0.3)) {
                            offset = finalOffset - dragOffset  // Adjust for smooth transition
                        } completion: {
                            dragOffset = 0 // Reset after animation completes
                            goToPreviousPage()
                            // Reset horizontal swiping after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isHorizontalSwiping = false
                            }
                        }
                    } else if predictedEndTranslation < -screenWidth / 3 && allEvents.count > 1 {
                        // Swipe left - go to next
                        // Start animation from current position (don't reset dragOffset yet)
                        let finalOffset = -screenWidth
                        withAnimation(.easeInOut(duration: 0.3)) {
                            offset = finalOffset - dragOffset  // Adjust for smooth transition
                        } completion: {
                            dragOffset = 0 // Reset after animation completes
                            goToNextPage()
                            // Reset horizontal swiping after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isHorizontalSwiping = false
                            }
                        }
                    } else {
                        // Reset to current page - animate back from current drag position
                        withAnimation(.easeOut(duration: 0.2)) {
                            offset = 0
                            dragOffset = 0 // Reset during animation for smooth return
                        } completion: {
                            // Reset horizontal swiping after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isHorizontalSwiping = false
                            }
                        }
                    }
                }
        )
    }
    
    // MARK: - Event Navigation
    
    private func goToPreviousPage() {
        let previousPage = (currentPage - 1 + allEvents.count) % allEvents.count
        let previousEvent = allEvents[previousPage]
        
        // Update the current event and page
        withAnimation(.none) {
            // Reset position instantly
            offset = 0
            
            // Update state
            currentPage = previousPage
            currentEvent = previousEvent
            
            // Update the map
            updateMapForEvent(previousEvent)
            
            // Update parent
            onEventChange?(previousEvent)
            
            // Check notification status
            checkNotificationStatus()
        }
    }
    
    private func goToNextPage() {
        let nextPage = (currentPage + 1) % allEvents.count
        let nextEvent = allEvents[nextPage]
        
        // Update the current event and page
        withAnimation(.none) {
            // Reset position instantly
            offset = 0
            
            // Update state
            currentPage = nextPage
            currentEvent = nextEvent
            
            // Update the map
            updateMapForEvent(nextEvent)
            
            // Update parent
            onEventChange?(nextEvent)
            
            // Check notification status
            checkNotificationStatus()
        }
    }
    
    // Update the map for a specific event
    private func updateMapForEvent(_ event: RAEvent) {
        if let venue = event.venue, let location = venue.location {
            let newCoordinate = CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )
            
            // Update both map representations
            mapRegion = MKCoordinateRegion(
                center: newCoordinate,
                span: MKCoordinateSpan(latitudeDelta: eventDetailMapSpanDelta, longitudeDelta: eventDetailMapSpanDelta)
            )
            
            if #available(iOS 17.0, *) {
                mapCameraPosition = .region(MKCoordinateRegion(
                    center: newCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: eventDetailMapSpanDelta, longitudeDelta: eventDetailMapSpanDelta)
                ))
            }
        }
    }
    
    // Check if there are any active notifications for this event
    private func checkNotificationStatus() {
        let identifierPrefix = "event-\(currentEvent.id)"
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let eventRequests = requests.filter { $0.identifier.hasPrefix(identifierPrefix) }
            DispatchQueue.main.async {
                self.hasActiveNotification = !eventRequests.isEmpty
            }
        }
    }
    
    private func startGenreBeat(for event: RAEvent) {
        guard let genres = event.genres, !genres.isEmpty else {
            genreBeatController.stop()
            return
        }
        genreBeatController.start(genres: genres, enabled: mapSettings.genreHapticsEnabled)
    }
}

// MARK: - Event Content View
struct EventContentView: View {
    let event: RAEvent
    @Binding var mapRegion: MKCoordinateRegion
    @Binding var mapCameraPosition: MapCameraPosition
    @Binding var showNotificationDialog: Bool
    @Binding var hasActiveNotification: Bool
    @ObservedObject var genreBeatController: GenreBeatController
    let isCurrentEvent: Bool
    let genreHapticsEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Event header with glitch gradient border
            VStack(alignment: .leading, spacing: 8) {
                // Event title with cyber styling and notification button
                HStack {
                    Text(event.title)
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .padding(.bottom, 2)
                        .overlay(
                            Rectangle()
                                .frame(height: 3)
                                .offset(y: 4)
                                .foregroundColor(.pink),
                            alignment: .bottom
                        )
                        
                    Spacer()
                    
                    if let url = event.residentAdvisorURL {
                        ShareLink(item: url, subject: Text(event.title), message: Text(event.title)) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    
                    Button {
                        showNotificationDialog = true
                    } label: {
                        ZStack {
                            Image(systemName: hasActiveNotification ? "bell.fill" : "bell.badge")
                                .font(.system(size: 24))
                                .foregroundColor(hasActiveNotification ? .pink : .green)
                            
                            if hasActiveNotification {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            
                // Date display with custom icon
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .foregroundColor(.pink)
                    Text(formatDateOnly(dateString: event.date))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
                
                // Time display as a separate row for better visibility
                if event.startTime != nil || event.endTime != nil {
                    HStack(spacing: 10) {
                        Image(systemName: "clock")
                            .foregroundColor(.pink)
                        if let formattedTimeRange = formatTimeRange(startTime: event.startTime, endTime: event.endTime) {
                            Text(formattedTimeRange)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        } else {
                            Text("TBA")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                    }
                }
            
                if let venue = event.venue {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "mappin.circle")
                            .foregroundColor(.pink)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(venue.name)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        
                            if let address = venue.address {
                                Text(address)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        
                            if let area = venue.area {
                                Text(area.name)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [.pink, .purple, .clear, .clear]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .padding(.horizontal)
            
            // Neo-punk popularity badge
            HStack {
                // Interest count
                HStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.pink)
                    
                    Text("\(event.interestedCount)")
                        .font(.system(.headline, design: .monospaced))
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    
                    Text("RAVERS")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.black)
                        .foregroundColor(.green)
                        .kerning(1)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.black.opacity(0.8))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(.pink, lineWidth: 1.5)
                )
            
                Spacer()
            
                if event.isTicketed {
                    Text("TICKETS")
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.black)
                        .kerning(1)
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.pink, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                }
            }
            .padding(.horizontal)
            
            // Neo-punk section header for Artists
            if !event.artists.isEmpty {
                sectionHeader(title: "ARTISTS")
                
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(event.artists) { artist in
                        HStack {
                            Text(artist.name)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            ArtistSocialLinksView(artist: artist)
                            
                            if let contentUrl = artist.contentUrl {
                                Button {
                                    if let url = URL(string: "https://ra.co\(contentUrl)") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    Image(systemName: "arrow.up.right.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 22))
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.vertical, 10)
            
                        
                        // Separator except for last item
                        if artist.id != event.artists.last?.id {
                            Rectangle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.clear, .pink.opacity(0.7), .clear]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(height: 1)
                                .padding(.horizontal)
                        }
                    }
                }
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            // Map section with neo-punk styling
            if let venue = event.venue, let venueLocation = venue.location {
                sectionHeader(title: "LOCATION")
                
                // iOS 17+ compatible map with fallback
                if #available(iOS 17.0, *) {
                    Map(position: $mapCameraPosition) {
                        Marker(venue.name, coordinate: CLLocationCoordinate2D(
                            latitude: venueLocation.latitude,
                            longitude: venueLocation.longitude
                        ))
                        .tint(.pink)
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [.green, .clear, .clear, .pink]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .padding(.horizontal)
                    .mapStyle(.standard(elevation: .realistic, pointsOfInterest: [.nightlife]))
                    .mapControlVisibility(.hidden)
                } else {
                    // Fallback for older iOS versions
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(
                            latitude: venueLocation.latitude,
                            longitude: venueLocation.longitude
                        ),
                        span: MKCoordinateSpan(latitudeDelta: eventDetailMapSpanDelta, longitudeDelta: eventDetailMapSpanDelta)
                    )), annotationItems: [venue]) { venueItem in
                        MapMarker(coordinate: CLLocationCoordinate2D(
                            latitude: venueItem.location?.latitude ?? 0,
                            longitude: venueItem.location?.longitude ?? 0
                        ), tint: .pink)
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [.green, .clear, .clear, .pink]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .padding(.horizontal)
                }
            }
            
            // Genres section
            if let genres = event.genres, !genres.isEmpty {
                sectionHeader(title: "GENRES")
                
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120), spacing: 8)
                ], spacing: 8) {
                    ForEach(genres) { genre in
                        GenrePillView(
                            genre: genre,
                            isActive: pillIsActive(genre: genre, genres: genres),
                            beatPulse: genreBeatController.beatPulse,
                            showsRotationDimming: isCurrentEvent && genreHapticsEnabled && genres.count > 1
                        )
                    }
                }
                .padding(.horizontal)
            }
        
            // Neo-punk action buttons
            VStack(spacing: 15) {
                Button {
                    if let url = event.residentAdvisorURL {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "globe")
                            .font(.system(.body, design: .monospaced))
                        Text("VIEW ON RA")
                            .font(.system(.headline, design: .monospaced))
                            .fontWeight(.black)
                            .kerning(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.pink, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
                
                Button {
                    if let url = URL(string: LegalURLs.disclaimer) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Event data from Resident Advisor")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                        .underline()
                }
                .buttonStyle(BorderlessButtonStyle())
            
                if let venue = event.venue {
                    Button {
                        if let contentUrl = venue.contentUrl, let url = URL(string: "https://ra.co\(contentUrl)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "mappin.circle")
                                .font(.system(.body, design: .monospaced))
                            Text("VENUE DETAILS")
                                .font(.system(.headline, design: .monospaced))
                                .fontWeight(.black)
                                .kerning(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.black)
                        .foregroundColor(.green)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(.green, lineWidth: 2)
                        )
                        .cornerRadius(8)
                    }
                }
            
                if let venue = event.venue, let location = venue.location {
                    Button {
                        let coordinates = "\(location.latitude),\(location.longitude)"
                        let query = venue.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: "http://maps.apple.com/?q=\(query)&ll=\(coordinates)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.turn.up.right.circle")
                                .font(.system(.body, design: .monospaced))
                            Text("GET DIRECTIONS")
                                .font(.system(.headline, design: .monospaced))
                                .fontWeight(.black)
                                .kerning(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.black)
                        .foregroundColor(.pink)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(.pink, lineWidth: 2)
                        )
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .padding(.vertical)
    }
    
    private func pillIsActive(genre: RAGenre, genres: [RAGenre]) -> Bool {
        guard isCurrentEvent, genreHapticsEnabled else { return false }
        if genres.count == 1 { return true }
        return genre.id == genreBeatController.activeGenreId
    }
    
    // Neo-punk section header
    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(.headline, design: .monospaced))
                .fontWeight(.black)
                .kerning(2)
                .foregroundColor(.pink)
            
            Spacer()
            
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [.pink, .clear]),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1.5)
                .padding(.leading, 8)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    // Helper functions
    private func formatTimeRange(startTime: String?, endTime: String?) -> String? {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        // Create multiple ISO formatters to handle different possible formats
        let isoFormatters = [
            // Standard ISO8601 with fractional seconds
            { () -> ISO8601DateFormatter in
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return formatter
            }(),
            // ISO8601 without fractional seconds
            { () -> ISO8601DateFormatter in
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime]
                return formatter
            }(),
            // Fallback date formatter for other ISO-like formats
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
                return formatter
            }()
        ]
        
        var formattedStart: String?
        var formattedEnd: String?
        
        // Parse start time using multiple formatters
        if let startTimeStr = startTime {
            for formatter in isoFormatters {
                if let date = (formatter as? ISO8601DateFormatter)?.date(from: startTimeStr) ?? 
                              (formatter as? DateFormatter)?.date(from: startTimeStr) {
                    formattedStart = timeFormatter.string(from: date)
                    break
                }
            }
            
            // If all formatters fail, try to extract time directly (fallback)
            if formattedStart == nil {
                // Extract time portion if it looks like ISO format
                if startTimeStr.contains("T") {
                    let components = startTimeStr.split(separator: "T")
                    if components.count > 1 {
                        let timeComponent = components[1]
                        if timeComponent.count >= 5 {
                            formattedStart = String(timeComponent.prefix(5)) // Take HH:mm
                        }
                    }
                }
            }
        }
        
        // Parse end time using multiple formatters
        if let endTimeStr = endTime {
            for formatter in isoFormatters {
                if let date = (formatter as? ISO8601DateFormatter)?.date(from: endTimeStr) ?? 
                              (formatter as? DateFormatter)?.date(from: endTimeStr) {
                    formattedEnd = timeFormatter.string(from: date)
                    break
                }
            }
            
            // If all formatters fail, try to extract time directly (fallback)
            if formattedEnd == nil {
                // Extract time portion if it looks like ISO format
                if endTimeStr.contains("T") {
                    let components = endTimeStr.split(separator: "T")
                    if components.count > 1 {
                        let timeComponent = components[1]
                        if timeComponent.count >= 5 {
                            formattedEnd = String(timeComponent.prefix(5)) // Take HH:mm
                        }
                    }
                }
            }
        }
        
        // Construct the time range string for neo-punk style - shorter format
        if let start = formattedStart {
            if let end = formattedEnd {
                return "\(start) → \(end)"
            }
            return start
        } else if let end = formattedEnd {
            return "→ \(end)"
        }
        
        return nil
    }
    
    private func formatDateOnly(dateString: String) -> String {
        // First try to parse as a full date
        let dateFormatters = [
            // Try standard date format first (yyyy-MM-dd)
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }(),
            // Try with time component
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                return formatter
            }()
        ]
        
        // Output formatter for consistent date display
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd MMM yyyy" // Shorter neo-punk date format
        
        // Try to parse and reformat the date
        for formatter in dateFormatters {
            if let date = formatter.date(from: dateString) {
                return outputFormatter.string(from: date).uppercased()
            }
        }
        
        // If we can't parse it, check if it contains a time component and remove it
        if dateString.contains("T") {
            let components = dateString.split(separator: "T")
            if components.count > 0 {
                // Just return the date part (before the T)
                let datePart = String(components[0])
                // Try to parse and format the date part
                if let dateFormatter = dateFormatters.first, 
                   let date = dateFormatter.date(from: datePart) {
                    return outputFormatter.string(from: date).uppercased()
                }
                return datePart // Return the raw date part if parsing fails
            }
        }
        
        // If all else fails, return the original string
        return dateString
    }
}

// Notification time options
enum NotificationTimeOption: String, CaseIterable, Identifiable {
    case tenMinutes = "10 minutes before"
    case thirtyMinutes = "30 minutes before"
    case oneHour = "1 hour before"
    case threeHours = "3 hours before"
    case oneDay = "1 day before"
    case threeDays = "3 days before"
    case oneWeek = "1 week before"
    
    var id: String { rawValue }
    
    var timeInterval: TimeInterval {
        switch self {
        case .tenMinutes: return 10 * 60
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .threeHours: return 3 * 60 * 60
        case .oneDay: return 24 * 60 * 60
        case .threeDays: return 3 * 24 * 60 * 60
        case .oneWeek: return 7 * 24 * 60 * 60
        }
    }
}

// Notification options dialog
struct NotificationOptionsView: View {
    let event: RAEvent
    @Binding var selectedTime: NotificationTimeOption
    @Binding var isPresented: Bool
    @Binding var hasActiveNotification: Bool
    @State private var isScheduling = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showDeleteConfirmation = false
    @ObservedObject private var devMode = DeveloperMode.shared
    private let logger = AppLogger.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Neo-punk background
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Notification for")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(.green)
                    
                    Text(event.title)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Show delete option if a notification is active
                    if hasActiveNotification {
                        Text("You already have a notification set for this event")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.pink)
                            .padding(.top, 5)
                        
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "bell.slash.fill")
                                Text("REMOVE NOTIFICATION")
                                    .font(.system(.headline, design: .monospaced))
                                    .fontWeight(.black)
                                    .kerning(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.black)
                            .foregroundColor(.pink)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(.pink, lineWidth: 2)
                            )
                            .cornerRadius(8)
                        }
                        .padding(.bottom, 20)
                    }
                    
                    Picker("Notify me", selection: $selectedTime) {
                        ForEach(NotificationTimeOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [.pink, .purple, .clear]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    
                    Button {
                        isScheduling = true
                        scheduleNotification()
                    } label: {
                        HStack {
                            Image(systemName: "bell.fill")
                            Text(hasActiveNotification ? "UPDATE REMINDER" : "SET REMINDER")
                                .font(.system(.headline, design: .monospaced))
                                .fontWeight(.black)
                                .kerning(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.pink, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.black)
                        .cornerRadius(8)
                    }
                    .disabled(isScheduling)
                    .overlay(
                        Group {
                            if isScheduling {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            }
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationBarTitle("Event Reminder", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertTitle.contains("Success") {
                            isPresented = false
                        }
                    }
                )
            }
            .alert("Remove Notification", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    deleteNotification()
                }
            } message: {
                Text("Are you sure you want to remove the notification for this event?")
            }
        }
    }
    
    private func scheduleNotification() {
        logger.debug("Starting to schedule notification for event: \(event.title)")
        
        if hasActiveNotification {
            logger.debug("Removing existing notification first")
            NotificationService.shared.cancelEventNotification(for: event)
        }
        
        NotificationService.shared.requestPermission { granted in
            if granted {
                logger.debug("Permission granted, scheduling notification")
                NotificationService.shared.scheduleEventNotification(
                    for: event, 
                    timeInterval: selectedTime.timeInterval
                )
                
                hasActiveNotification = true
                
                if devMode.isEnabled {
                    alertTitle = "Success"
                    alertMessage = "Notification set for \(selectedTime.rawValue) the event."
                    showAlert = true
                } else {
                    isPresented = false
                }
                
                logger.debug("Notification scheduled successfully")
            } else {
                logger.debug("Permission denied")
                alertTitle = "Permission Denied"
                alertMessage = "Please enable notifications for this app in Settings to receive event reminders."
                showAlert = true
            }
            
            isScheduling = false
        }
    }
    
    private func deleteNotification() {
        NotificationService.shared.cancelEventNotification(for: event)
        hasActiveNotification = false
        
        if devMode.isEnabled {
            alertTitle = "Notification Removed"
            alertMessage = "The notification for this event has been removed."
            showAlert = true
        }
    }
} 