import Foundation
import UserNotifications
import UIKit

class NotificationService {
    static let shared = NotificationService()
    
    private let logger = AppLogger.shared
    
    private init() {
        // Private initializer for singleton
    }
    
    // Request notification permissions
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.logger.error("Notification permission error: \(error.localizedDescription)")
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
            
            self.logger.debug("Found \(requests.count) total notifications")
            
            for request in requests {
                if request.identifier.hasPrefix("event-") {
                    self.logger.debug("Processing event notification: \(request.identifier)")
                    
                    let components = request.identifier.split(separator: "-")
                    if components.count >= 2 {
                        let eventId = String(components[1])
                        
                        var eventTitle = "Unknown Event"
                        var eventDate = "Unknown Date"
                        var notifyTime = "Unknown Time"
                        
                        eventTitle = request.content.body
                            .replacingOccurrences(of: "'", with: "")
                            .replacingOccurrences(of: "' is coming up soon!", with: "")
                        
                        self.logger.debug("Notification content: \(request.content.body)")
                        self.logger.debug("Extracted title: \(eventTitle)")
                        
                        let userInfo = request.content.userInfo
                        self.logger.debug("UserInfo: \(userInfo)")
                        
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
                        
                        self.logger.debug("Adding notification: \(notification.eventTitle) on \(notification.eventDate)")
                        notifications.append(notification)
                    }
                }
            }
            
            notifications.sort { $0.notificationDate < $1.notificationDate }
            
            self.logger.debug("Returning \(notifications.count) notifications")
            
            let badgeCount = notifications.count
            DispatchQueue.main.async {
                if #available(iOS 17.0, *) {
                    UNUserNotificationCenter.current().setBadgeCount(badgeCount) { error in
                        if let error = error {
                            self.logger.error("Failed to update badge count: \(error.localizedDescription)")
                        }
                    }
                } else {
                    @available(iOS, deprecated: 17.0, message: "Use UNUserNotificationCenter.setBadgeCount instead")
                    func setLegacyBadge(_ count: Int) {
                        UIApplication.shared.applicationIconBadgeNumber = count
                    }
                    setLegacyBadge(badgeCount)
                    self.logger.debug("Updated app badge number to \(badgeCount) using legacy API")
                }
                
                completion(notifications)
            }
        }
    }
    
    func cancelNotificationById(_ identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        updateBadgeCount()
    }
    
    private func parseEventDate(dateString: String, startTime: String?) -> Date? {
        logger.debug("Parsing date: \(dateString), startTime: \(startTime ?? "nil")")
        
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
        
        for formatter in dateOnlyFormatters {
            if let date = (formatter as? ISO8601DateFormatter)?.date(from: dateString) ??
                          (formatter as? DateFormatter)?.date(from: dateString) {
                
                logger.debug("Successfully parsed date: \(date)")
                
                if let timeString = startTime {
                    for timeFormatter in timeFormatters {
                        if let timeDate = (timeFormatter as? ISO8601DateFormatter)?.date(from: timeString) ??
                                          (timeFormatter as? DateFormatter)?.date(from: timeString) {
                            
                            var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                            let timeComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: timeDate)
                            
                            components.hour = timeComponents.hour
                            components.minute = timeComponents.minute
                            components.second = timeComponents.second
                            
                            if let combinedDate = Calendar.current.date(from: components) {
                                logger.debug("Combined with time: \(combinedDate)")
                                return combinedDate
                            }
                        }
                    }
                    
                    var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                    components.hour = 12
                    components.minute = 0
                    if let noonDate = Calendar.current.date(from: components) {
                        logger.debug("Using noon time: \(noonDate)")
                        return noonDate
                    }
                } else {
                    var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                    components.hour = 12
                    components.minute = 0
                    if let noonDate = Calendar.current.date(from: components) {
                        logger.debug("No time provided, using noon: \(noonDate)")
                        return noonDate
                    }
                }
                
                return date
            }
        }
        
        logger.error("Failed to parse date string: \(dateString)")
        logger.debug("Using emergency fallback date (tomorrow noon)")
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        var components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = 12
        components.minute = 0
        return Calendar.current.date(from: components)
    }
    
    func scheduleEventNotification(for event: RAEvent, timeInterval: TimeInterval) {
        logger.debug("Scheduling notification for event \(event.id): \(event.title)")
        logger.debug("Event date info - date: \(event.date), startTime: \(event.startTime ?? "nil")")
        
        requestPermission { [weak self] granted in
            guard let self = self, granted else {
                self?.logger.debug("Notification permission not granted")
                return
            }
            
            guard let eventDate = self.parseEventDate(dateString: event.date, startTime: event.startTime) else {
                self.logger.error("Could not parse event date - using fallback")
                let fallbackDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
                self.scheduleWithDate(event: event, eventDate: fallbackDate, timeInterval: timeInterval)
                return
            }
            
            self.scheduleWithDate(event: event, eventDate: eventDate, timeInterval: timeInterval)
        }
    }
    
    private func scheduleWithDate(event: RAEvent, eventDate: Date, timeInterval: TimeInterval) {
        logger.debug("Scheduling with confirmed date: \(eventDate)")
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event Reminder"
        content.body = "'\(event.title)' is coming up soon!"
        content.sound = .default
        content.badge = 1
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        let formattedDate = formatter.string(from: eventDate)
        
        var notifyTimeString = "Before event"
        if timeInterval == 10 * 60 { notifyTimeString = "10 minutes before" }
        else if timeInterval == 30 * 60 { notifyTimeString = "30 minutes before" }
        else if timeInterval == 60 * 60 { notifyTimeString = "1 hour before" }
        else if timeInterval == 3 * 60 * 60 { notifyTimeString = "3 hours before" }
        else if timeInterval == 24 * 60 * 60 { notifyTimeString = "1 day before" }
        else if timeInterval == 3 * 24 * 60 * 60 { notifyTimeString = "3 days before" }
        else if timeInterval == 7 * 24 * 60 * 60 { notifyTimeString = "1 week before" }
        
        let eventDetails: [String: String] = [
            "title": event.title,
            "date": formattedDate,
            "notifyTime": notifyTimeString
        ]
        content.userInfo["eventDetails"] = eventDetails
        
        logger.debug("Set userInfo: \(eventDetails)")
        
        let identifier = "event-\(event.id)-\(Int(timeInterval))"
        logger.debug("Creating notification with ID: \(identifier)")
        
        let notificationTime = eventDate.timeIntervalSince1970 - timeInterval
        
        if notificationTime > Date().timeIntervalSince1970 {
            let triggerDate = Date(timeIntervalSince1970: notificationTime)
            let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            
            logger.debug("Trigger set for: \(triggerDate)")
            
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    self.logger.error("Error scheduling notification: \(error.localizedDescription)")
                } else {
                    self.logger.info("Notification scheduled successfully for \(event.title) at \(triggerDate)")
                    
                    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                        let match = requests.first { $0.identifier == identifier }
                        self.logger.debug("Verification - \(match != nil ? "Notification found" : "Notification NOT found")")
                        self.updateBadgeCount()
                    }
                }
            }
        } else {
            logger.error("Cannot schedule notification for past time")
        }
    }
    
    func cancelEventNotification(for event: RAEvent) {
        let identifierPrefix = "event-\(event.id)"
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let eventRequests = requests.filter { $0.identifier.hasPrefix(identifierPrefix) }
            let identifiers = eventRequests.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            self.logger.info("Canceled \(identifiers.count) notifications for event \(event.title)")
            self.updateBadgeCount()
        }
    }
    
    private func updateBadgeCount() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let eventNotifications = requests.filter { $0.identifier.hasPrefix("event-") }
            let badgeCount = eventNotifications.count
            
            DispatchQueue.main.async {
                if #available(iOS 17.0, *) {
                    UNUserNotificationCenter.current().setBadgeCount(badgeCount) { error in
                        if let error = error {
                            self.logger.error("Failed to update badge count: \(error.localizedDescription)")
                        } else {
                            self.logger.debug("Updated app badge number to \(badgeCount) using new API")
                        }
                    }
                } else {
                    @available(iOS, deprecated: 17.0, message: "Use UNUserNotificationCenter.setBadgeCount instead")
                    func setLegacyBadge(_ count: Int) {
                        UIApplication.shared.applicationIconBadgeNumber = count
                    }
                    setLegacyBadge(badgeCount)
                    self.logger.debug("Updated app badge number to \(badgeCount) using legacy API")
                }
            }
        }
    }
}
