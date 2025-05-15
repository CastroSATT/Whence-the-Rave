import Foundation

// Model for event notifications
struct EventNotification: Identifiable {
    let id: String
    let eventId: String
    let eventTitle: String
    let eventDate: String
    let notifyTime: String
    let notificationDate: Date
    
    var formattedTimeRemaining: String {
        let now = Date()
        if now > notificationDate {
            return "Scheduled for past time"
        }
        
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: now, to: notificationDate)
        
        if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") before event"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") before event"
        } else if let minutes = components.minute {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") before event"
        } else {
            return "Less than a minute"
        }
    }
} 