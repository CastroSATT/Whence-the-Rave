import Foundation
import UserNotifications
import UIKit

class NotificationService {
    static let shared = NotificationService()
    
    private init() {
        // Private initializer for singleton
    }
    
    // Request notification permissions
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(granted)
                }
            }
        }
    }
    
    // Get all active event notifications
    func getAllEventNotifications(completion: @escaping ([EventNotification]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            var notifications: [EventNotification] = []
            
            print("💬 DEBUG: Found \(requests.count) total notifications")
            
            for request in requests {
                // Only process event notifications
                if request.identifier.hasPrefix("event-") {
                    print("💬 DEBUG: Processing event notification: \(request.identifier)")
                    
                    // Extract information from the identifier: "event-{eventId}-{timeInterval}"
                    let components = request.identifier.split(separator: "-")
                    if components.count >= 2 {
                        let eventId = String(components[1])
                        
                        // Get notification and event details
                        var eventTitle = "Unknown Event"
                        var eventDate = "Unknown Date"
                        var notifyTime = "Unknown Time"
                        
                        // Try to extract information from the content first
                        eventTitle = request.content.body
                            .replacingOccurrences(of: "'", with: "")
                            .replacingOccurrences(of: "' is coming up soon!", with: "")
                        
                        print("💬 DEBUG: - Notification content: \(request.content.body)")
                        print("💬 DEBUG: - Extracted title: \(eventTitle)")
                        
                        // Check userInfo
                        let userInfo = request.content.userInfo
                        print("💬 DEBUG: - UserInfo: \(userInfo)")
                        
                        // Get details from userInfo if available
                        if let details = userInfo["eventDetails"] as? [String: String] {
                            if let title = details["title"] {
                                eventTitle = title
                            }
                            if let date = details["date"] {
                                eventDate = date
                            }
                            if let time = details["notifyTime"] {
                                notifyTime = time
                            }
                        }
                        
                        // Get notification trigger date
                        var notificationDate = Date()
                        if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                           let date = Calendar.current.date(from: trigger.dateComponents) {
                            notificationDate = date
                        } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                            notificationDate = Date(timeIntervalSinceNow: trigger.timeInterval)
                        }
                        
                        let notification = EventNotification(
                            id: request.identifier,
                            eventId: eventId,
                            eventTitle: eventTitle,
                            eventDate: eventDate,
                            notifyTime: notifyTime,
                            notificationDate: notificationDate
                        )
                        
                        print("💬 DEBUG: Adding notification: \(notification.eventTitle) on \(notification.eventDate)")
                        notifications.append(notification)
                    }
                }
            }
            
            // Sort by notification date
            notifications.sort { $0.notificationDate < $1.notificationDate }
            
            print("💬 DEBUG: Returning \(notifications.count) notifications")
            
            // Update app badge number to match notification count
            let badgeCount = notifications.count
            DispatchQueue.main.async {
                // Update badge count with the new API (iOS 17+) or fallback
                if #available(iOS 17.0, *) {
                    UNUserNotificationCenter.current().setBadgeCount(badgeCount) { error in
                        if let error = error {
                            print("🔔 ERROR: Failed to update badge count: \(error.localizedDescription)")
                        }
                    }
                } else {
                    // Fallback for iOS 16 and earlier
                    @available(iOS, deprecated: 17.0, message: "Use UNUserNotificationCenter.setBadgeCount instead")
                    func setLegacyBadge(_ count: Int) {
                        UIApplication.shared.applicationIconBadgeNumber = count
                    }
                    setLegacyBadge(badgeCount)
                    print("🔔 DEBUG: Updated app badge number to \(badgeCount) using legacy API")
                }
                
                completion(notifications)
            }
        }
    }
    
    // Cancel a notification by identifier
    func cancelNotificationById(_ identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        
        // Update badge count after cancellation
        updateBadgeCount()
    }
    
    // Helper to parse event date string to Date object
    private func parseEventDate(dateString: String, startTime: String?) -> Date? {
        print("🔔 DEBUG: Parsing date: \(dateString), startTime: \(startTime ?? "nil")")
        
        // Create date formatters
        let dateOnlyFormatters = [
            ISO8601DateFormatter(),
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }()
        ]
        
        let timeFormatters = [
            ISO8601DateFormatter(),
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                return formatter
            }(),
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return formatter
            }()
        ]
        
        // Try to parse date
        for formatter in dateOnlyFormatters {
            if let date = (formatter as? ISO8601DateFormatter)?.date(from: dateString) ?? 
                          (formatter as? DateFormatter)?.date(from: dateString) {
                
                print("🔔 DEBUG: Successfully parsed date: \(date)")
                
                // If we have a time string, parse and combine with date
                if let timeString = startTime {
                    for timeFormatter in timeFormatters {
                        if let timeDate = (timeFormatter as? ISO8601DateFormatter)?.date(from: timeString) ?? 
                                          (timeFormatter as? DateFormatter)?.date(from: timeString) {
                            
                            // Combine date and time
                            var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                            let timeComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: timeDate)
                            
                            components.hour = timeComponents.hour
                            components.minute = timeComponents.minute
                            components.second = timeComponents.second
                            
                            if let combinedDate = Calendar.current.date(from: components) {
                                print("🔔 DEBUG: Combined with time: \(combinedDate)")
                                return combinedDate
                            }
                        }
                    }
                    
                    // Fallback to noon if we couldn't parse the time
                    var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                    components.hour = 12
                    components.minute = 0
                    if let noonDate = Calendar.current.date(from: components) {
                        print("🔔 DEBUG: Using noon time: \(noonDate)")
                        return noonDate
                    }
                } else {
                    // No time provided, use noon
                    var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                    components.hour = 12
                    components.minute = 0
                    if let noonDate = Calendar.current.date(from: components) {
                        print("🔔 DEBUG: No time provided, using noon: \(noonDate)")
                        return noonDate
                    }
                }
                
                // If we at least have a date, return it even without time
                return date
            }
        }
        
        // If we couldn't parse the date with any formatter
        print("🔔 ERROR: Failed to parse date string: \(dateString)")
        
        // Emergency fallback - use tomorrow at noon if we can't parse the date
        print("🔔 DEBUG: Using emergency fallback date (tomorrow noon)")
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        var components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = 12
        components.minute = 0
        return Calendar.current.date(from: components)
    }
    
    // Schedule notification for an event
    func scheduleEventNotification(for event: RAEvent, timeInterval: TimeInterval) {
        print("🔔 DEBUG: NotificationService - Scheduling notification for event \(event.id): \(event.title)")
        print("🔔 DEBUG: Event date info - date: \(event.date), startTime: \(event.startTime ?? "nil")")
        
        // First check if we have permission
        requestPermission { [weak self] granted in
            guard let self = self, granted else {
                print("🔔 DEBUG: NotificationService - Permission not granted")
                return
            }
            
            // Parse the event date first to make sure we have valid data
            guard let eventDate = self.parseEventDate(dateString: event.date, startTime: event.startTime) else {
                print("🔔 ERROR: Could not parse event date - using fallback")
                // Use fallback date (1 week from now)
                let fallbackDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
                
                // Continue with fallback date
                self.scheduleWithDate(event: event, eventDate: fallbackDate, timeInterval: timeInterval)
                return
            }
            
            // Continue with valid date
            self.scheduleWithDate(event: event, eventDate: eventDate, timeInterval: timeInterval)
        }
    }
    
    // Helper to schedule with a confirmed date
    private func scheduleWithDate(event: RAEvent, eventDate: Date, timeInterval: TimeInterval) {
        print("🔔 DEBUG: Scheduling with confirmed date: \(eventDate)")
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event Reminder"
        content.body = "'\(event.title)' is coming up soon!"
        content.sound = .default
        content.badge = 1
        
        // Store event details in userInfo for later retrieval
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        let formattedDate = formatter.string(from: eventDate)
        
        // Get a human-readable notification time description
        var notifyTimeString = "Before event"
        if timeInterval == 10 * 60 { notifyTimeString = "10 minutes before" }
        else if timeInterval == 30 * 60 { notifyTimeString = "30 minutes before" }
        else if timeInterval == 60 * 60 { notifyTimeString = "1 hour before" }
        else if timeInterval == 3 * 60 * 60 { notifyTimeString = "3 hours before" }
        else if timeInterval == 24 * 60 * 60 { notifyTimeString = "1 day before" }
        else if timeInterval == 3 * 24 * 60 * 60 { notifyTimeString = "3 days before" }
        else if timeInterval == 7 * 24 * 60 * 60 { notifyTimeString = "1 week before" }
        
        // Create properly formatted userInfo
        let eventDetails: [String: String] = [
            "title": event.title,
            "date": formattedDate,
            "notifyTime": notifyTimeString
        ]
        content.userInfo["eventDetails"] = eventDetails
        
        print("🔔 DEBUG: NotificationService - Set userInfo: \(eventDetails)")
        
        // Create a unique identifier for this event notification
        let identifier = "event-\(event.id)-\(Int(timeInterval))"
        print("🔔 DEBUG: NotificationService - Creating notification with ID: \(identifier)")
        
        // Calculate when to send the notification (event time minus the selected interval)
        let notificationTime = eventDate.timeIntervalSince1970 - timeInterval
        
        // Only schedule if the notification time is in the future
        if notificationTime > Date().timeIntervalSince1970 {
            let triggerDate = Date(timeIntervalSince1970: notificationTime)
            
            // Use a calendar trigger for more reliable scheduling 
            let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            
            print("🔔 DEBUG: NotificationService - Trigger set for: \(triggerDate)")
            
            // Create the request
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            // Schedule the notification
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("🔔 ERROR: Error scheduling notification: \(error.localizedDescription)")
                } else {
                    print("🔔 SUCCESS: Notification scheduled successfully for \(event.title) at \(triggerDate)")
                    
                    // Verify notification was created
                    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                        let match = requests.first { $0.identifier == identifier }
                        print("🔔 DEBUG: Verification - \(match != nil ? "Notification found" : "❌ Notification NOT found")")
                        
                        // Update badge count after scheduling
                        self.updateBadgeCount()
                    }
                }
            }
        } else {
            print("🔔 ERROR: Cannot schedule notification for past time")
        }
    }
    
    // Cancel notification for an event
    func cancelEventNotification(for event: RAEvent) {
        // Cancel all notifications related to this event
        let identifierPrefix = "event-\(event.id)"
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let eventRequests = requests.filter { $0.identifier.hasPrefix(identifierPrefix) }
            let identifiers = eventRequests.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            print("Canceled \(identifiers.count) notifications for event \(event.title)")
            
            // Update badge count after cancellation
            self.updateBadgeCount()
        }
    }
    
    // Helper to update the app icon badge count
    private func updateBadgeCount() {
        // Get pending notifications count and update badge
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let eventNotifications = requests.filter { $0.identifier.hasPrefix("event-") }
            let badgeCount = eventNotifications.count
            
            DispatchQueue.main.async {
                // Use new API for iOS 17+ and fall back to old API for older versions
                if #available(iOS 17.0, *) {
                    UNUserNotificationCenter.current().setBadgeCount(badgeCount) { error in
                        if let error = error {
                            print("🔔 ERROR: Failed to update badge count: \(error.localizedDescription)")
                        } else {
                            print("🔔 DEBUG: Updated app badge number to \(badgeCount) using new API")
                        }
                    }
                } else {
                    // Fallback for iOS 16 and earlier
                    @available(iOS, deprecated: 17.0, message: "Use UNUserNotificationCenter.setBadgeCount instead")
                    func setLegacyBadge(_ count: Int) {
                        UIApplication.shared.applicationIconBadgeNumber = count
                    }
                    setLegacyBadge(badgeCount)
                    print("🔔 DEBUG: Updated app badge number to \(badgeCount) using legacy API")
                }
            }
        }
    }
} 