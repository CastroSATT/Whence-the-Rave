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
                    .foregroundColor(.gray)
                    .font(.caption)
                
                Text(formatDate(dateString: event.date))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let timeText = formatTime(startTime: event.startTime, endTime: event.endTime) {
                    Text("•")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    Text(timeText)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            if let venue = event.venue {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .foregroundColor(.gray)
                        .font(.caption)
                    
                    Text(venue.name)
                        .font(.caption)
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
        }
        .padding(.vertical, 4)
    }
    
    // Helper function to format date
    private func formatDate(dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .medium
            outputFormatter.timeStyle = .none
            return outputFormatter.string(from: date)
        }
        
        // Fallback to original string
        return dateString
    }
    
    // Helper function to format time range
    private func formatTime(startTime: String?, endTime: String?) -> String? {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        // Create ISO formatters
        let isoFormatter = ISO8601DateFormatter()
        
        var formattedStart: String?
        var formattedEnd: String?
        
        // Parse start time
        if let startTimeStr = startTime, let date = isoFormatter.date(from: startTimeStr) {
            formattedStart = timeFormatter.string(from: date)
        }
        
        // Parse end time
        if let endTimeStr = endTime, let date = isoFormatter.date(from: endTimeStr) {
            formattedEnd = timeFormatter.string(from: date)
        }
        
        // Construct time range string
        if let start = formattedStart {
            if let end = formattedEnd {
                return "\(start)-\(end)"
            }
            return start
        } else if let end = formattedEnd {
            return "→\(end)"
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
                        .foregroundColor(.gray)
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
                            .foregroundColor(.gray)
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
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }
    
    // Helper function to format date - neo-punk style (shorter)
    private func formatDate(dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "dd MMM"
            return outputFormatter.string(from: date).uppercased()
        }
        
        return dateString
    }
    
    // Helper function for time formatting - neo-punk style (shorter)
    private func formatTime(startTime: String?, endTime: String?) -> String? {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        // Create ISO formatters
        let isoFormatter = ISO8601DateFormatter()
        
        var formattedStart: String?
        var formattedEnd: String?
        
        // Parse start time
        if let startTimeStr = startTime, let date = isoFormatter.date(from: startTimeStr) {
            formattedStart = timeFormatter.string(from: date)
        }
        
        // Parse end time
        if let endTimeStr = endTime, let date = isoFormatter.date(from: endTimeStr) {
            formattedEnd = timeFormatter.string(from: date)
        }
        
        // Construct time range string
        if let start = formattedStart {
            if let end = formattedEnd {
                return "\(start)→\(end)"
            }
            return start
        } else if let end = formattedEnd {
            return "→\(end)"
        }
        
        return nil
    }
} 