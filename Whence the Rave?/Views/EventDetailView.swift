import SwiftUI
import MapKit

struct EventDetailView: View {
    let event: RAEvent
    @State private var mapRegion: MKCoordinateRegion
    @State private var mapCameraPosition: MapCameraPosition
    @Environment(\.colorScheme) private var colorScheme
    
    init(event: RAEvent) {
        self.event = event
        
        // Initialize map region
        if let venue = event.venue, let location = venue.location {
            let initialCoordinate = CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )
            _mapRegion = State(initialValue: MKCoordinateRegion(
                center: initialCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
            _mapCameraPosition = State(initialValue: .region(MKCoordinateRegion(
                center: initialCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
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
    
    var body: some View {
        ZStack {
            // Neo-punk background
            Color.black.edgesIgnoringSafeArea(.all)
            
        ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Event header with glitch gradient border
                    VStack(alignment: .leading, spacing: 8) {
                        // Event title with cyber styling
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
                            Map(coordinateRegion: $mapRegion, annotationItems: [venue]) { venueItem in
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
                                Text(genre.name)
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.green, .cyan]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                    }
                
                    // Neo-punk action buttons
                    VStack(spacing: 15) {
                    Button {
                        if let url = URL(string: "https://ra.co\(event.contentUrl)") {
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
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
    
    // Helper function to parse and format time range properly
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
    
    // Helper function to extract only the date portion from a date string
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