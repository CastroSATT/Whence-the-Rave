import Foundation
import Combine
import CoreLocation
import SwiftUI

class EventViewModel: ObservableObject {
    @Published var events: [RAEvent] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var selectedArea: RACountryArea?
    @Published var searchDate: SearchDateOption = .today
    @Published var sortOption: SortOption = .popular
    @Published var isAutoSelectingArea: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = RAApiClient.shared
    private let locationService = LocationService.shared
    private let logger = AppLogger.shared
    
    enum SearchDateOption: String, CaseIterable, Identifiable {
        case today = "Today"
        case tomorrow = "Tomorrow"
        case week = "Next 7 days"
        case twoWeeks = "Next 14 days"
        case month = "Next 30 days"
        
        var id: String { self.rawValue }
        
        var days: Int {
            switch self {
            case .today: return 0
            case .tomorrow: return 1
            case .week: return 7
            case .twoWeeks: return 14
            case .month: return 30
            }
        }
    }
    
    enum SortOption: String, CaseIterable, Identifiable {
        case latest = "Latest"
        case popular = "Popular"
        case alphabetical = "A-Z"
        
        var id: String { self.rawValue }
        
        var apiValue: String {
            switch self {
            case .latest: return "LATEST"
            case .popular: return "POPULAR"
            case .alphabetical: return "ALPHABETICAL"
            }
        }
    }
    
    init() {
        logger.info("EventViewModel initialized")
        
        // Track published property changes
        setupPropertyObservers()
        
        // Setup location service observers
        locationService.$currentLocation
            .sink { [weak self] location in
                if let location = location {
                    self?.logger.debug("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                }
            }
            .store(in: &cancellables)
        
        // Observe the nearest area property from LocationService
        locationService.$nearestArea
            .dropFirst() // Skip initial nil value
            .sink { [weak self] area in
                guard let self = self, let area = area else { return }
                
                self.logger.info("Nearest area updated: \(area.name) (ID: \(area.id))")
                
                // Auto-select the area if none is currently selected
                self.autoSelectNearestArea()
            }
            .store(in: &cancellables)
    }
    
    private func setupPropertyObservers() {
        // Log when selection or search parameters change
        $selectedArea
            .dropFirst()
            .sink { [weak self] area in
                if let area = area {
                    self?.logger.info("Area selected: \(area.name) (ID: \(area.id))")
                } else {
                    self?.logger.info("Area selection cleared")
                }
            }
            .store(in: &cancellables)
        
        $searchDate
            .dropFirst()
            .sink { [weak self] option in
                self?.logger.info("Search date option changed: \(option.rawValue) (\(option.days) days)")
            }
            .store(in: &cancellables)
        
        $sortOption
            .dropFirst()
            .sink { [weak self] option in
                self?.logger.info("Sort option changed: \(option.rawValue) (\(option.apiValue))")
            }
            .store(in: &cancellables)
        
        $events
            .dropFirst()
            .sink { [weak self] events in
                self?.logger.info("Events updated: \(events.count) events loaded")
            }
            .store(in: &cancellables)
    }
    
    func findEvents() {
        guard let selectedArea = selectedArea else {
            logger.warning("Attempted to search without selecting an area")
            self.error = "Please select an area first"
            return
        }
        
        logger.info("Starting event search for area: \(selectedArea.name) (ID: \(selectedArea.id))")
        
        isLoading = true
        error = nil
        
        // Calculate date range from today
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let today = Date()
        let calendar = Calendar.current
        
        // Set the date range based on search option
        let dateFrom: String
        let dateTo: String
        
        switch searchDate {
        case .today:
            // Just today
            dateFrom = formatter.string(from: today)
            dateTo = dateFrom
            logger.debug("Filtering events for TODAY ONLY: \(dateFrom)")
            
        case .tomorrow:
            // Just tomorrow
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            dateFrom = formatter.string(from: tomorrow)
            dateTo = dateFrom
            logger.debug("Filtering events for TOMORROW ONLY: \(dateFrom)")
            
        default:
            // Date range starting from today
            dateFrom = formatter.string(from: today)
            var dateComponents = DateComponents()
            dateComponents.day = searchDate.days
            let endDate = calendar.date(byAdding: dateComponents, to: today) ?? today
            dateTo = formatter.string(from: endDate)
            logger.debug("Filtering events for date range: \(dateFrom) to \(dateTo) (\(searchDate.days) days)")
        }
        
        logger.debug("Search parameters - Date range: \(dateFrom) to \(dateTo), Sort: \(sortOption.apiValue)")
        
        // Use the paginated API method that handles multiple pages
        apiClient.getAllEventsByArea(
            areaId: selectedArea.id,
            dateFrom: dateFrom,
            dateTo: dateTo,
            sort: sortOption.apiValue,
            pageSize: 100
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                switch completion {
                case .finished:
                    self?.logger.info("Event search completed successfully")
                case .failure(let error):
                    self?.error = error.localizedDescription
                    self?.logger.error("Event search failed: \(error.localizedDescription)")
                }
            },
            receiveValue: { [weak self] response in
                // Check for GraphQL errors
                if let errors = response.errors, !errors.isEmpty {
                    let errorMessages = errors.map { $0.message }.joined(separator: ", ")
                    self?.error = "API Error: \(errorMessages)"
                    self?.logger.error("GraphQL errors: \(errorMessages)")
                    self?.events = []
                    return
                }
                
                // Guard against null data
                guard let eventData = response.data?.eventListingsWithBumps?.eventListings.data else {
                    self?.error = "No event data received"
                    self?.logger.warning("No event data in response")
                    self?.events = []
                    return
                }
                
                let events = eventData.map { $0.event }
                self?.events = events
                
                let totalResults = response.data?.eventListingsWithBumps?.eventListings.totalResults ?? 0
                self?.logger.info("Received \(events.count) events (total results: \(totalResults))")
                
                if events.isEmpty {
                    self?.error = "No events found for this date range"
                } else {
                    self?.error = nil
                }
                
                // Log summary of events by venue
                let venueGroups = Dictionary(grouping: events) { $0.venue?.name ?? "Unknown venue" }
                self?.logger.debug("Events by venue:")
                venueGroups.forEach { venue, venueEvents in
                    self?.logger.debug("  \(venue): \(venueEvents.count) events")
                }
                
                // Log any events without proper location data
                let eventsWithoutLocation = events.filter { $0.venue?.location == nil }
                if !eventsWithoutLocation.isEmpty {
                    self?.logger.warning("\(eventsWithoutLocation.count) events have no location data")
                    eventsWithoutLocation.forEach { event in
                        self?.logger.debug("  Missing location: \(event.title) at \(event.venue?.name ?? "unknown venue")")
                    }
                }
                
                // Count and log events with valid location data
                let eventsWithLocation = events.filter { $0.venue?.location != nil }
                self?.logger.info("\(eventsWithLocation.count)/\(events.count) events have valid location data for map display")
                
                // Add debug coordinates for events with missing location data
                self?.addDebugCoordinatesForMissingLocations()
            }
        )
        .store(in: &cancellables)
    }
    
    // Add debug coordinates for events with missing location data
    private func addDebugCoordinatesForMissingLocations() {
        let eventsWithoutLocation = events.filter { $0.venue?.location == nil }
        
        if !eventsWithoutLocation.isEmpty {
            logger.info("Adding debug coordinates for \(eventsWithoutLocation.count) events with missing location data")
            
            // Deep copy of current events
            var updatedEvents = events
            
            // Default coordinates for London (slightly randomized for visibility)
            let baseLatitude = 51.5074
            let baseLongitude = -0.1278
            
            for i in 0..<updatedEvents.count {
                // Only update events with missing location data
                if updatedEvents[i].venue?.location == nil {
                    // Create a random offset to spread events without coordinates
                    let latOffset = Double.random(in: -0.02...0.02)
                    let lonOffset = Double.random(in: -0.02...0.02)
                    
                    // Create a location if venue exists but has no location
                    if var venue = updatedEvents[i].venue {
                        venue.location = RALocation(
                            latitude: baseLatitude + latOffset,
                            longitude: baseLongitude + lonOffset
                        )
                        updatedEvents[i].venue = venue
                        logger.debug("Added debug coordinates for event: \(updatedEvents[i].title)")
                    } 
                    // Create venue with location if venue is missing entirely
                    else {
                        let debugVenue = RAVenue(
                            id: "debug-\(updatedEvents[i].id)",
                            name: "(Unknown Venue)",
                            contentUrl: nil,
                            address: "Debug location",
                            area: RAArea(name: "London"),
                            location: RALocation(
                                latitude: baseLatitude + latOffset,
                                longitude: baseLongitude + lonOffset
                            ),
                            live: false
                        )
                        updatedEvents[i].venue = debugVenue
                        logger.debug("Created debug venue with coordinates for event: \(updatedEvents[i].title)")
                    }
                }
            }
            
            // Update events with the modified copies
            self.events = updatedEvents
            logger.info("Updated \(eventsWithoutLocation.count) events with debug coordinates")
        }
    }
    
    func runDiagnostics() {
        logger.info("Running API diagnostics")
        
        // First, try to diagnose the GraphQL schema
        apiClient.diagnoseGraphQLSchema()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.logger.info("GraphQL schema query completed")
                    case .failure(let error):
                        self?.logger.error("GraphQL schema query failed: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] data in
                    self?.logger.info("Received GraphQL schema data: \(data.count) bytes")
                    
                    // Try to parse it to see what we're working with
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                        do {
                            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
                            if let jsonString = String(data: prettyData, encoding: .utf8) {
                                self?.logger.debug("GraphQL schema (pretty):\n\(jsonString)")
                            }
                        } catch {
                            self?.logger.warning("Could not pretty-print JSON: \(error.localizedDescription)")
                        }
                    } else {
                        self?.logger.warning("Could not parse GraphQL schema as JSON")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // Auto-select the nearest area based on user's current location
    func autoSelectNearestArea() {
        guard selectedArea == nil, !isAutoSelectingArea else { return }
        
        isAutoSelectingArea = true
        logger.info("Auto-selecting nearest area based on location")
        
        if let nearestArea = locationService.nearestArea {
            logger.info("Auto-selected area: \(nearestArea.name) (ID: \(nearestArea.id))")
            selectedArea = nearestArea
            
            // Automatically search for events in this area
            findEvents()
        } else {
            // Try to find nearest area if not already cached
            if let foundArea = locationService.findNearestArea() {
                logger.info("Found and auto-selected area: \(foundArea.name) (ID: \(foundArea.id))")
                selectedArea = foundArea
                
                // Automatically search for events in this area
                findEvents()
            } else {
                logger.warning("Failed to auto-select area - no suitable area found")
            }
        }
        
        isAutoSelectingArea = false
    }
} 