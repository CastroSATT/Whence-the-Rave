import SwiftUI
import os.log
import UserNotifications

/// Represents the navigation tabs on the right side of the map
struct NavigationTabsView: View {
    // State bindings
    @Binding var showEventList: Bool
    @Binding var showNearbyEvents: Bool
    @Binding var dragOffset: CGFloat
    @Binding var showSettings: Bool
    @State private var showNotificationsManager: Bool = false
    @State private var activeNotificationCount: Int = 0
    
    // Logger for debug info
    private let logger = AppLogger.shared
    private let osLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.whencetheraves", category: "NavigationTabsView")
    
    // Actions
    var onLocationButtonTap: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            // Alarm bell button
            Button(action: {
                osLogger.debug("🔔 Alarm bell button tapped")
                showNotificationsManager = true
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.8))
                        .frame(width: 40, height: 80)
                    
                    VStack(spacing: 16) {
                        ZStack {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                            
                            // Notification count badge
                            if activeNotificationCount > 0 {
                                ZStack {
                                    Circle()
                                        .fill(Color.pink)
                                        .frame(width: 16, height: 16)
                                    
                                    Text("\(activeNotificationCount > 9 ? "9+" : "\(activeNotificationCount)")")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .offset(x: 12, y: -12)
                            }
                        }
                        
                        Text("ALM")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.pink)
                    }
                    .padding(.vertical, 8)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [.orange, .pink, .purple]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                )
            }
            .buttonStyle(BorderlessButtonStyle())
            .shadow(color: .black.opacity(0.3), radius: 5, x: 2, y: 2)
            .opacity(showEventList ? 1 : 0)
            .scaleEffect(showEventList ? 1 : 0.7)
            .offset(x: showEventList ? 0 : 100) // Slide in from right
            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(showEventList ? 0.2 : 0), value: showEventList)
            .sheet(isPresented: $showNotificationsManager, onDismiss: {
                osLogger.debug("📱 Notifications manager dismissed")
                // Update notification count when closed
                checkActiveNotifications()
            }) {
                NotificationsManagerView()
                    .id(UUID()) // Force view recreation each time it's shown
            }
            .onAppear {
                osLogger.debug("📱 Alarm bell button view initialized")
                osLogger.debug("Alarm bell button configuration - width: 40, height: 80, cornerRadius: 8")
                checkActiveNotifications()
            }
            // Use newer onChange API for iOS 17+
            #if compiler(>=5.9) && canImport(Observation)
            .onChange(of: showNotificationsManager) {
                // Update notification count when notification manager is dismissed
                if !showNotificationsManager {
                    checkActiveNotifications()
                }
            }
            #else
            // Legacy onChange API for older iOS versions
            .onChange(of: showNotificationsManager) { newValue in
                // Update notification count when notification manager is dismissed
                if !newValue {
                    checkActiveNotifications()
                }
            }
            #endif
            // Update badge when the slide panel is opened or closed
            #if compiler(>=5.9) && canImport(Observation)
            .onChange(of: showEventList) {
                // Refresh badge count when panel state changes
                checkActiveNotifications()
            }
            #else
            // Legacy onChange API for older iOS versions
            .onChange(of: showEventList) { newValue in
                // Refresh badge count when panel state changes
                checkActiveNotifications()
            }
            #endif
            .accessibilityIdentifier("alarmBellButton")
            
            // Events list pull tab
            Button(action: {
                osLogger.debug("🔘 Events list pull tab tapped")
                osLogger.debug("Current state - showEventList: \(showEventList), showNearbyEvents: \(showNearbyEvents), dragOffset: \(dragOffset)")
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if !showEventList {
                        osLogger.debug("Opening event list panel")
                        showEventList = true
                        showNearbyEvents = false
                        // Update badge count when the panel opens
                        checkActiveNotifications()
                    } else if showNearbyEvents {
                        osLogger.debug("Switching from nearby to regular events")
                        showNearbyEvents = false
                    } else {
                        osLogger.debug("Closing event list panel")
                        showEventList = false
                        // Update badge count when the panel closes
                        checkActiveNotifications()
                    }
                    dragOffset = 0
                }
                
                osLogger.debug("Final state - showEventList: \(showEventList), showNearbyEvents: \(showNearbyEvents), dragOffset: \(dragOffset)")
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.8))
                        .frame(width: 40, height: 80)
                    
                    VStack(spacing: 12) {
                        Image(systemName: showEventList ? "chevron.left" : "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.pink)
                        
                        Image(systemName: "list.bullet")
                            .font(.system(size: 16))
                            .foregroundColor(showNearbyEvents ? .pink : .green)
                    }
                    .padding(.vertical, 8)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [.pink, .purple, .green]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                )
            }
            .buttonStyle(BorderlessButtonStyle())
            .shadow(color: .black.opacity(0.3), radius: 5, x: 2, y: 2)
            .onAppear {
                osLogger.debug("📱 Events list pull tab view initialized")
                osLogger.debug("Pull tab configuration - width: 40, height: 80, cornerRadius: 8")
            }
            .accessibilityIdentifier("eventListPullTab")
            
            // Location button
            Button(action: {
                osLogger.debug("📍 Location button tapped")
                onLocationButtonTap()
                osLogger.debug("Location button action completed")
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.8))
                        .frame(width: 40, height: 80)
                    
                    VStack(spacing: 16) {
                        Image(systemName: "location.magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                        
                        Text("LOC")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.pink)
                    }
                    .padding(.vertical, 8)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .blue, .pink]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                )
            }
            .buttonStyle(BorderlessButtonStyle())
            .shadow(color: .black.opacity(0.3), radius: 5, x: 2, y: 2)
            .onAppear {
                osLogger.debug("📱 Location button view initialized")
                osLogger.debug("Location button configuration - width: 40, height: 80, cornerRadius: 8")
            }
            .accessibilityIdentifier("locationButton")
            
            // Settings button - only visible when panel is open
            Button(action: {
                osLogger.debug("⚙️ Settings button tapped")
                showSettings = true
                osLogger.debug("Settings button action completed - showSettings: \(showSettings)")
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.8))
                        .frame(width: 40, height: 80)
                    
                    VStack(spacing: 16) {
                        Image(systemName: "gear")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                        
                        Text("CFG")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.pink)
                    }
                    .padding(.vertical, 8)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .pink, .orange]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                )
            }
            .buttonStyle(BorderlessButtonStyle())
            .shadow(color: .black.opacity(0.3), radius: 5, x: 2, y: 2)
            .opacity(showEventList ? 1 : 0)
            .scaleEffect(showEventList ? 1 : 0.7)
            .offset(x: showEventList ? 0 : 100) // Slide in from right
            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(showEventList ? 0.2 : 0), value: showEventList)
            .onAppear {
                osLogger.debug("📱 Settings button view initialized")
                osLogger.debug("Settings button configuration - width: 40, height: 80, cornerRadius: 8")
            }
            .accessibilityIdentifier("settingsButton")
        }
        .frame(width: 40)
        .onAppear {
            osLogger.debug("NavigationTabsView appeared with zIndex: 2")
            osLogger.debug("Navigation tabs layout - width: 40, spacing: 10")
            checkActiveNotifications()
        }
        // Set up a timer to periodically refresh the badge count
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
            // Refresh notification count every 30 seconds
            checkActiveNotifications()
        }
    }
    
    // Check for active notifications
    private func checkActiveNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let eventNotifications = requests.filter { $0.identifier.hasPrefix("event-") }
            let count = eventNotifications.count
            
            DispatchQueue.main.async {
                self.activeNotificationCount = count
                self.osLogger.debug("Updated badge count: \(self.activeNotificationCount) pending event notifications")
                
                // Update app badge number using the appropriate API
                if #available(iOS 17.0, *) {
                    UNUserNotificationCenter.current().setBadgeCount(count) { error in
                        if let error = error {
                            self.osLogger.error("Failed to update badge count: \(error.localizedDescription)")
                        }
                    }
                } else {
                    // Fallback for iOS 16 and earlier
                    @available(iOS, deprecated: 17.0, message: "Use UNUserNotificationCenter.setBadgeCount instead")
                    func setLegacyBadge(_ count: Int) {
                        UIApplication.shared.applicationIconBadgeNumber = count
                    }
                    setLegacyBadge(count)
                }
            }
        }
    }
} 