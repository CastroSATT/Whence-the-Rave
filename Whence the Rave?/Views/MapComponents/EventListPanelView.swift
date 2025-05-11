import SwiftUI
import UIKit
import os.log

/// Represents the sliding event list panel on the left side of the map
struct EventListPanelView: View {
    // View model
    @ObservedObject var viewModel: EventViewModel
    
    // State bindings
    @Binding var selectedEvent: RAEvent?
    @Binding var showEventSheet: Bool
    @Binding var showEventList: Bool
    @Binding var showNearbyEvents: Bool
    @Binding var dragOffset: CGFloat
    @Binding var showingAreaPicker: Bool
    @Binding var showSettings: Bool
    
    // Panel dimensions
    let panelWidth: CGFloat
    
    // Enhanced logging
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.whencetheraves", category: "EventListPanelView")
    
    // Logic for sorting nearby events by distance
    var distanceToEventLogic: (RAEvent) -> Double
    
    var body: some View {
        VStack {
            // Title bar for the list
            panelHeader
                .onAppear {
                    logger.debug("Panel header view appeared, panelWidth: \(panelWidth)")
                }
            
            if showNearbyEvents {
                nearbyEventsContent
            } else if viewModel.events.isEmpty {
                emptyEventsContent
            } else {
                regularEventsContent
            }
        }
        .frame(width: panelWidth)
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .pink.opacity(0.3), .clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 1),
            alignment: .trailing
        )
        .onAppear {
            logger.debug("EventListPanelView appeared with zIndex configuration")
        }
    }
    
    // MARK: - Panel Header
    
    private var panelHeader: some View {
        HStack {
            Spacer()
            
            // Empty space where buttons used to be
            // This maintains the header height and layout
            Rectangle()
                .fill(Color.clear)
                .frame(width: 60, height: 35) // Approximate space of both buttons
            .padding(.trailing)
        }
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.pink),
            alignment: .bottom
        )
        .onAppear {
            logger.debug("Panel header layout details:")
            logger.debug("Header background: Color.black.opacity(0.8)")
            logger.debug("Header vertical padding: 12")
            logger.debug("Using empty space instead of buttons to maintain layout")
        }
    }
    
    // MARK: - Nearby Events Content
    
    private var nearbyEventsContent: some View {
        Group {
            if viewModel.events.isEmpty {
                VStack {
                    Spacer()
                    VStack {
                        Image(systemName: "location.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.pink)
                        
                        Text("SEARCHING NEARBY")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                    Spacer()
                }
            } else {
                // Nearby events list - use EventListItem directly since it's already defined
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.events.sorted { 
                            distanceToEventLogic($0) < distanceToEventLogic($1)
                        }) { event in
                            eventListItem(for: event)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Empty Events Content
    
    private var emptyEventsContent: some View {
        VStack {
            Spacer()
            VStack {
                Image(systemName: "music.note.list")
                    .font(.system(size: 40))
                    .foregroundColor(.pink)
                
                Text("NO EVENTS FOUND")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
            Spacer()
        }
    }
    
    // MARK: - Regular Events Content
    
    private var regularEventsContent: some View {
        VStack {
            // Search controls section
            searchControls
            
            // Event list - use EventListItem directly since it's already defined
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.events) { event in
                        eventListItem(for: event)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // Helper method to create event list items consistently
    private func eventListItem(for event: RAEvent) -> some View {
        VStack(spacing: 0) {
            Button(action: {
                selectedEvent = event
                showEventSheet = true
            }) {
                NeoPunkEventListItem(event: event)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Add separator below each item
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .pink.opacity(0.6), .clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.vertical, 8)
        }
    }
    
    // MARK: - Search Controls
    
    private var searchControls: some View {
        VStack(spacing: 6) {
            // Location row - more compact
            HStack(spacing: 4) {
                Text("LOC")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                    .frame(width: 30, alignment: .leading)
                
                Button {
                    viewModel.autoSelectNearestArea()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.isAutoSelectingArea)
                
                Button(viewModel.selectedArea?.name ?? "Select Area") {
                    showingAreaPicker = true
                }
                .font(.system(size: 12))
                .lineLimit(1)
                .foregroundColor(.white)
                
                Spacer()
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.vertical, 2)
            
            // Two-column layout for time and sort
            HStack(spacing: 8) {
                // Time Period column
                HStack(spacing: 4) {
                    Text("TIME")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                        .frame(width: 30, alignment: .leading)
                    
                    Picker("", selection: $viewModel.searchDate) {
                        ForEach(EventViewModel.SearchDateOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                }
                
                Spacer()
                
                // Sort column
                HStack(spacing: 4) {
                    Text("SORT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                        .frame(width: 30, alignment: .leading)
                    
                    Picker("", selection: $viewModel.sortOption) {
                        ForEach(EventViewModel.SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                }
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.vertical, 2)
            
            // Compact Find Events button
            Button {
                logger.debug("Find events button tapped")
                viewModel.findEvents()
            } label: {
                Text("FIND EVENTS")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.7), .purple.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            .disabled(viewModel.selectedArea == nil || viewModel.isLoading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.8))
    }
    
    // Simple logger since we don't have direct access to AppLogger
    private struct Logger {
        let subsystem: String
        let category: String
        
        func debug(_ message: String) {
            #if DEBUG
            print("DEBUG: \(message)")
            #endif
        }
    }
} 