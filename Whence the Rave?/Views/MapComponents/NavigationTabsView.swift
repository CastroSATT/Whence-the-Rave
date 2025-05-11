import SwiftUI
import os.log

/// Represents the navigation tabs on the right side of the map
struct NavigationTabsView: View {
    // State bindings
    @Binding var showEventList: Bool
    @Binding var showNearbyEvents: Bool
    @Binding var dragOffset: CGFloat
    @Binding var showSettings: Bool
    
    // Logger for debug info
    private let logger = AppLogger.shared
    private let osLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.whencetheraves", category: "NavigationTabsView")
    
    // Actions
    var onLocationButtonTap: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            // Events list pull tab
            Button(action: {
                osLogger.debug("🔘 Events list pull tab tapped")
                osLogger.debug("Current state - showEventList: \(showEventList), showNearbyEvents: \(showNearbyEvents), dragOffset: \(dragOffset)")
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if !showEventList {
                        osLogger.debug("Opening event list panel")
                        showEventList = true
                        showNearbyEvents = false
                    } else if showNearbyEvents {
                        osLogger.debug("Switching from nearby to regular events")
                        showNearbyEvents = false
                    } else {
                        osLogger.debug("Closing event list panel")
                        showEventList = false
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
        }
    }
} 