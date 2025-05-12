import SwiftUI

// Basic event list item for display in lists
struct EventListItem: View {
    let event: RAEvent
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.headline)
                .lineLimit(2)
            
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .foregroundColor(.pink)
                    .font(.system(size: 12))
                
                Text(formatDate(dateString: event.date))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.green)
                    .fontWeight(.medium)
                
                if let timeText = formatTime(startTime: event.startTime, endTime: event.endTime) {
                    Text("•")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    Image(systemName: "clock")
                        .foregroundColor(.pink)
                        .font(.system(size: 12))
                    
                    Text(timeText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
            }
            
            if let venue = event.venue {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .foregroundColor(.pink)
                        .font(.system(size: 12))
                    
                    Text(venue.name)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            // Interested count and ticket badge
            HStack {
                Image(systemName: "person.3")
                    .foregroundColor(.gray)
                    .font(.caption2)
                
                Text("\(event.interestedCount) interested")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if event.isTicketed {
                    Text("Ticketed")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
            
            // Genre tags
            if let genres = event.genres, !genres.isEmpty {
                HStack {
                    Image(systemName: "music.note")
                        .foregroundColor(.gray)
                        .font(.caption2)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(genres.prefix(3)) { genre in
                                Text(genre.name)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .clipShape(Capsule())
                            }
                            
                            if genres.count > 3 {
                                Text("+\(genres.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // Helper function to format date
    private func formatDate(dateString: String) -> String {
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
            }(),
            // Try with fractional seconds
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
                return formatter
            }()
        ]
        
        // Output formatter for consistent date display
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd MMM yyyy"
        
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
    
    // Helper function to format time range
    private func formatTime(startTime: String?, endTime: String?) -> String? {
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
        
        // Construct time range string with arrow like detail view
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
}

// Neo-punk styled event list item
struct NeoPunkEventListItem: View {
    let event: RAEvent
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Event title with glitch effect border
            Text(event.title)
                .font(.system(.headline, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
                .padding(.bottom, 2)
            
            // Date and time with icons
            HStack(spacing: 6) {
                // Date
                HStack(spacing: 2) {
                    Image(systemName: "calendar")
                        .foregroundColor(.pink)
                        .font(.system(size: 10))
                    
                    Text(formatDate(dateString: event.date))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.green)
                }
                
                // Divider dot
                if let _ = formatTime(startTime: event.startTime, endTime: event.endTime) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 3, height: 3)
                    
                    // Time
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .foregroundColor(.pink)
                            .font(.system(size: 10))
                        
                        Text(formatTime(startTime: event.startTime, endTime: event.endTime) ?? "TBA")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Venue with icon
            if let venue = event.venue {
                HStack(spacing: 2) {
                    Image(systemName: "mappin")
                        .foregroundColor(.pink)
                        .font(.system(size: 10))
                    
                    Text(venue.name)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            // Bottom row with interested count and ticket info
            HStack {
                // Interest count
                HStack(spacing: 2) {
                    Text("\(event.interestedCount)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                    
                    Text("RAVERS")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .kerning(0.5)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Ticket badge
                if event.isTicketed {
                    Text("TICKETS")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .kerning(0.5)
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.pink, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
            }
            
            // Genre tags (if available)
            if let genres = event.genres, !genres.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(genres.prefix(3)) { genre in
                            Text(genre.name)
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.green, .cyan]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                        }
                        
                        if genres.count > 3 {
                            Text("+\(genres.count - 3)")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                                .padding(.horizontal, 4)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }
    
    // Helper function to format date - neo-punk style (shorter)
    private func formatDate(dateString: String) -> String {
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
            }(),
            // Try with fractional seconds
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
                return formatter
            }()
        ]
        
        // Output formatter for consistent date display - shorter for neo-punk style
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd MMM"
        
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
    
    // Helper function for time formatting - neo-punk style (shorter)
    private func formatTime(startTime: String?, endTime: String?) -> String? {
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
        
        // Construct time range string with arrow like detail view (more compact for neo-punk)
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
}

struct ArtistSocialLinksView: View {
    let artist: RAArtist
    @State private var socialLinks: ArtistSocialLinks?
    @State private var isLoading = false
    @State private var error: Error?
    
    private let apiClient = RAApiClient()
    
    var body: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.5)
            } else if error != nil {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
                    .font(.system(size: 14))
                    .help(error?.localizedDescription ?? "Failed to load social links")
            } else if let links = socialLinks {
                if let soundcloud = links.soundcloud {
                    SocialLinkButton(url: soundcloud, icon: "waveform")
                }
                if let instagram = links.instagram {
                    SocialLinkButton(url: instagram, icon: "camera")
                }
                if let twitter = links.twitter {
                    SocialLinkButton(url: twitter, icon: "bird")
                }
                if let bandcamp = links.bandcamp {
                    SocialLinkButton(url: bandcamp, icon: "music.note")
                }
                if let discogs = links.discogs {
                    SocialLinkButton(url: discogs, icon: "vinyl")
                }
                if let website = links.website {
                    SocialLinkButton(url: website, icon: "globe")
                }
            }
        }
        .onAppear {
            fetchArtistDetails()
        }
    }
    
    private func fetchArtistDetails() {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                let links = try await apiClient.fetchArtistDetails(artistId: artist.id)
                await MainActor.run {
                    self.socialLinks = links
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
}

struct SocialLinkButton: View {
    let url: String
    let icon: String
    
    var body: some View {
        Button {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        } label: {
            if icon == "vinyl" { // Discogs special case
                Text("D")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.pink)
                    .frame(width: 24, height: 24)
                    .background(Color.black.opacity(0.8))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(.pink, lineWidth: 1)
                    )
            } else {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.pink)
                    .frame(width: 24, height: 24)
                    .background(Color.black.opacity(0.8))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(.pink, lineWidth: 1)
                    )
            }
        }
        .buttonStyle(.borderless)
    }
} 