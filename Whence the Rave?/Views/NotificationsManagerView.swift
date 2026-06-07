import SwiftUI
import UserNotifications
import UIKit

struct NotificationsManagerView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var activeNotifications: [EventNotification] = []
    @State private var isLoading = true
    @State private var debugMessage: String = ""
    @State private var viewAppeared = false
    @State private var selectedEvent: SelectedEventDetail?
    
    // Add reference to developer mode
    @ObservedObject private var devMode = DeveloperMode.shared
    private let logger = AppLogger.shared
    
    var body: some View {
        ZStack {
                // Neo-punk background
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Header
                    HStack {
                        Text("NOTIFICATIONS")
                            .font(.system(.title2, design: .monospaced))
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
                        
                        // Refresh button
                        Button {
                            loadNotifications()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                        }
                        .padding(.trailing, 12)
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding()
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                            .scaleEffect(1.5)
                        Spacer()
                    } else if activeNotifications.isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("NO ACTIVE NOTIFICATIONS")
                                .font(.system(.headline, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            
                            Text("You don't have any event reminders set up")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray.opacity(0.7))
                                .multilineTextAlignment(.center)
                            
                            // Debug message - only show when dev mode is enabled
                            if !debugMessage.isEmpty && devMode.isEnabled {
                                Text(debugMessage)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.pink.opacity(0.8))
                                    .padding(.top, 20)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Test notification button - only show when dev mode is enabled
                            if devMode.isEnabled {
                                Button {
                                    createTestNotification()
                                } label: {
                                    Text("CREATE TEST NOTIFICATION")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.pink.opacity(0.6))
                                        .cornerRadius(8)
                                }
                                .padding(.top, 20)
                            }
                        }
                        Spacer()
                    } else {
                        List {
                            // Show debug message at the top of the list if dev mode is enabled
                            if !debugMessage.isEmpty && devMode.isEnabled {
                                Text(debugMessage)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.pink.opacity(0.8))
                                    .listRowBackground(Color.black.opacity(0.8))
                            }
                            
                            ForEach(activeNotifications) { notification in
                                Button {
                                    selectedEvent = SelectedEventDetail(eventId: notification.eventId)
                                } label: {
                                    NotificationRow(notification: notification)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .listRowBackground(Color.black.opacity(0.8))
                                .swipeActions {
                                    Button(role: .destructive) {
                                        deleteNotification(notification)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            
                            // Add test notification button at the bottom if dev mode is enabled
                            if devMode.isEnabled {
                                Button {
                                    createTestNotification()
                                } label: {
                                    HStack {
                                        Image(systemName: "bell.badge.fill")
                                            .foregroundColor(.pink)
                                        Text("CREATE TEST NOTIFICATION")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.white)
                                    }
                                }
                                .listRowBackground(Color.black.opacity(0.8))
                            }
                        }
                        .listStyle(.plain)
                        .background(Color.black)
                    }
                }
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailLoader(eventId: event.eventId)
                .presentationDetents([.medium, .large])
        }
        .task {
            // Load notifications on initial view appearance
            logger.debug("NotificationsManagerView - task triggered")
            if !viewAppeared {
                viewAppeared = true
                loadNotifications()
            }
        }
        .onAppear {
            logger.debug("NotificationsManagerView - onAppear called")
            // Load notifications on each appearance
            loadNotifications()
        }
        .onDisappear {
            logger.debug("NotificationsManagerView - onDisappear called")
        }
    }
    
    private func loadNotifications() {
        logger.debug("NotificationsManagerView - Loading notifications")
        isLoading = true
        
        // Use direct UNUserNotificationCenter API for reliability
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            // Filter for only event notifications
            let eventRequests = requests.filter { $0.identifier.hasPrefix("event-") }
            let notifCount = requests.count
            let eventCount = eventRequests.count
            
            self.logger.debug("Found \(notifCount) total notifications, \(eventCount) event notifications")
            self.debugMessage = "System found: \(notifCount) total, \(eventCount) event notifications"
            
            // Create notifications from the requests directly
            var notifications: [EventNotification] = []
            
            for request in eventRequests {
                self.logger.debug("Processing notification: \(request.identifier)")
                
                // Extract event ID from identifier
                let components = request.identifier.split(separator: "-")
                if components.count >= 2 {
                    let eventId = String(components[1])
                    
                    // Extract notification info
                    var eventTitle = "Unknown Event"
                    var eventDate = "Unknown Date"
                    var notifyTime = "Unknown Time"
                    
                    // 1. Try to get data from userInfo
                    if let details = request.content.userInfo["eventDetails"] as? [String: String] {
                        self.logger.debug("Found details in userInfo dictionary: \(details)")
                        eventTitle = details["title"] ?? eventTitle
                        eventDate = details["date"] ?? eventDate
                        notifyTime = details["notifyTime"] ?? notifyTime
                    } 
                    // 2. Try userInfo as AnyHashable
                    else if let details = request.content.userInfo["eventDetails"] as? [AnyHashable: Any] {
                        self.logger.debug("Found details as AnyHashable dict: \(details)")
                        if let title = details["title"] as? String { eventTitle = title }
                        if let date = details["date"] as? String { eventDate = date }
                        if let time = details["notifyTime"] as? String { notifyTime = time }
                    } 
                    // 3. Fallback to notification content
                    else {
                        self.logger.debug("No details in userInfo, using content")
                        // Clean up the body text to get the event title
                        eventTitle = request.content.body
                            .replacingOccurrences(of: "'", with: "")
                            .replacingOccurrences(of: "' is coming up soon!", with: "")
                    }
                    
                    // Get notification time
                    var notificationDate = Date()
                    if let trigger = request.trigger as? UNCalendarNotificationTrigger, 
                       let date = Calendar.current.date(from: trigger.dateComponents) {
                        notificationDate = date
                        self.logger.debug("Using calendar trigger date: \(date)")
                    } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                        let fireDate = Date(timeIntervalSinceNow: trigger.timeInterval)
                        notificationDate = fireDate
                        self.logger.debug("Using time interval trigger date: \(fireDate)")
                    }
                    
                    self.logger.debug("Creating notification object - ID: \(request.identifier), Title: \(eventTitle)")
                    
                    // Create the notification object
                    let notification = EventNotification(
                        id: request.identifier,
                        eventId: eventId,
                        eventTitle: eventTitle,
                        eventDate: eventDate,
                        notifyTime: notifyTime,
                        notificationDate: notificationDate
                    )
                    
                    notifications.append(notification)
                }
            }
            
            self.logger.debug("Parsed \(notifications.count) notifications out of \(eventRequests.count) requests")
            
            // Sort by notification date
            notifications.sort { $0.notificationDate < $1.notificationDate }
            
            // Update on main thread
            DispatchQueue.main.async {
                self.activeNotifications = notifications
                self.isLoading = false
                
                self.logger.debug("Updated UI with \(notifications.count) notifications")
                self.debugMessage += "\nDisplaying \(notifications.count) notifications"
            }
        }
    }
    
    private func deleteNotification(_ notification: EventNotification) {
        NotificationService.shared.cancelNotificationById(notification.id)
        if let index = activeNotifications.firstIndex(where: { $0.id == notification.id }) {
            activeNotifications.remove(at: index)
        }
    }
    
    private func createTestNotification() {
        // Create and schedule a test notification for debugging
        logger.debug("Creating test notification")
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event Reminder"
        content.body = "'Test Event' is coming up soon!"
        content.sound = .default
        content.badge = 1 // Set badge number to 1
        
        // Get current time for unique ID and date display
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let timeString = dateFormatter.string(from: now)
        
        // Store event details in userInfo with dictionary literal (more reliable)
        let eventDetails: [String: String] = [
            "title": "Test Event (\(timeString))",
            "date": "31 DEC 2025",
            "notifyTime": "1 hour before"
        ]
        content.userInfo["eventDetails"] = eventDetails
        
        // Create a unique identifier with timestamp
        let identifier = "event-test\(Int(now.timeIntervalSince1970))-3600"
        
        // Set trigger for 20 seconds in the future (for quick testing)
        // Using Calendar trigger which is more reliable for persistence
        let futureDate = Date(timeIntervalSinceNow: 20)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: futureDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        logger.debug("Test notification will fire at: \(futureDate)")
        
        // Create the request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Test notification error: \(error)")
            } else {
                self.logger.info("Test notification created with ID: \(identifier)")
                
                // Verify notification was registered
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    // Get all event notifications
                    let allNotifications = requests.filter { $0.identifier.hasPrefix("event-") }
                    let thisNotification = requests.first { $0.identifier == identifier }
                    
                    self.logger.debug("Verification - Total notifications: \(requests.count)")
                    self.logger.debug("Verification - Event notifications: \(allNotifications.count)")
                    self.logger.debug("Verification - Test notification found: \(thisNotification != nil)")
                    
                    // Reload notifications after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.loadNotifications()
                        
                        // Update app badge number to match notification count
                        let badgeCount = allNotifications.count
                        if #available(iOS 17.0, *) {
                            UNUserNotificationCenter.current().setBadgeCount(badgeCount) { error in
                                if let error = error {
                                    self.logger.error("Failed to update badge count: \(error.localizedDescription)")
                                } else {
                                    self.logger.debug("Updated app badge number to \(badgeCount) using new API")
                                }
                            }
                        } else {
                            // Fallback for iOS 16 and earlier
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
    }
}

private struct SelectedEventDetail: Identifiable {
    let eventId: String
    var id: String { eventId }
}

struct NotificationRow: View {
    let notification: EventNotification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Event Title
            Text(notification.eventTitle)
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
            
            HStack(spacing: 12) {
                // Event Date
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .foregroundColor(.pink)
                        .font(.system(size: 12))
                    
                    Text(notification.eventDate)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                }
                
                // Notification Time
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .foregroundColor(.pink)
                        .font(.system(size: 12))
                    
                    Text(notification.notifyTime)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                }
            }
            
            // Notification details
            Text("Notification: \(notification.formattedTimeRemaining)")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.pink)
                .padding(.top, 2)
        }
        .padding(.vertical, 8)
    }
}

// Model for event notifications is now in a separate file 