//
//  ContentView.swift
//  Whence the Rave?
//
//  Created by Jason Mark Allen on 07/05/2025.
//

import SwiftUI
import CoreLocation
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = EventViewModel()
    @StateObject private var locationService = LocationService.shared
    
    var body: some View {
            NavigationStack {
                EventMapView(viewModel: viewModel)
        }
        .onAppear {
            // Request location permissions when app launches
            locationService.requestLocationPermission()
            
            // Start location updates right away if already authorized
            if locationService.locationStatus == .authorizedWhenInUse || 
               locationService.locationStatus == .authorizedAlways {
                locationService.startLocationUpdates()
            }
        }
    }
}

struct EventSearchView: View {
    @ObservedObject var viewModel: EventViewModel
    @State private var showingAreaPicker = false
    @State private var showDebugOptions = false
    
    var body: some View {
        VStack {
            // Search filters
            VStack(spacing: 12) {
                HStack {
                    Text("Location:")
                        .bold()
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button {
                            viewModel.autoSelectNearestArea()
                        } label: {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(viewModel.isAutoSelectingArea)
                        
                        Button(viewModel.selectedArea?.name ?? "Select Area") {
                            showingAreaPicker = true
                        }
                    }
                    .sheet(isPresented: $showingAreaPicker) {
                        AreaPickerView(selectedArea: $viewModel.selectedArea)
                            .presentationDetents([.medium, .large])
                    }
                }
                
                HStack {
                    Text("Time Period:")
                        .bold()
                    
                    Spacer()
                    
                    Picker("Time Period", selection: $viewModel.searchDate) {
                        ForEach(EventViewModel.SearchDateOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                HStack {
                    Text("Sort By:")
                        .bold()
                    
                    Spacer()
                    
                    Picker("Sort By", selection: $viewModel.sortOption) {
                        ForEach(EventViewModel.SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Button("Find Events") {
                    viewModel.findEvents()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedArea == nil || viewModel.isLoading)
                
                // Debug section - long press to reveal
                if showDebugOptions {
                    Divider()
                        .padding(.vertical, 8)
                    
                    Text("Debug Options")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Run API Diagnostics") {
                        viewModel.runDiagnostics()
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .font(.callout)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .onLongPressGesture {
                // Toggle debug options with long press
                withAnimation {
                    showDebugOptions.toggle()
                }
            }
            
            // Results
            if viewModel.isLoading {
                ProgressView("Loading events...")
                    .padding()
                Spacer()
            } else if let error = viewModel.error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
                Spacer()
            } else if viewModel.events.isEmpty {
                VStack {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                        .padding()
                    Text("No events found")
                        .font(.headline)
                    Text("Try changing your search criteria")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                Spacer()
            } else {
                List {
                    ForEach(viewModel.events) { event in
                        NavigationLink {
                            EventDetailView(event: event)
                        } label: {
                            EventRowView(event: event)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct EventRowView: View {
    let event: RAEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.headline)
                .lineLimit(1)
            
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
                Text(formatDateOnly(dateString: event.date))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Add time if available
                if event.startTime != nil || event.endTime != nil {
                    Text("•")
                        .foregroundColor(.gray)
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                    if let timeText = formatTimeRange(startTime: event.startTime, endTime: event.endTime) {
                        Text(timeText)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                if let venue = event.venue {
                    Text("•")
                        .foregroundColor(.gray)
                    Image(systemName: "mappin.circle")
                        .foregroundColor(.gray)
                    Text(venue.name)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            HStack {
                Image(systemName: "person.3")
                    .foregroundColor(.gray)
                Text("\(event.interestedCount) interested")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if event.isTicketed {
                    Text("Ticketed")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // Helper function to extract only the date portion
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
        outputFormatter.dateStyle = .medium
        outputFormatter.timeStyle = .none
        
        // Try to parse and reformat the date
        for formatter in dateFormatters {
            if let date = formatter.date(from: dateString) {
                return outputFormatter.string(from: date)
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
                    return outputFormatter.string(from: date)
                }
                return datePart // Return the raw date part if parsing fails
            }
        }
        
        // If all else fails, return the original string
        return dateString
    }
    
    // Helper function to format time range
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
        
        // Construct a compact time range string for list view
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

#Preview {
    ContentView()
}
