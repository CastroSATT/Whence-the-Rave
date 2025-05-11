import SwiftUI
import MapKit
import os.log
import Combine

// We're using module imports here. In a real project, you'd use:
// import MapComponents or similar depending on your module structure

// Main view for the event map screen
struct EventMapView: View {
    @ObservedObject var viewModel: EventViewModel
    @ObservedObject private var mapSettings = MapSettings.shared
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.5074, longitude: 0.1278), // Default to London
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedEvent: RAEvent?
    @State private var showEventSheet = false
    @State private var mapError: String?
    @State private var initialLocationSet = false
    @State private var forceMapRefresh = false // Added state variable to force map refresh
    @State private var currentUnit: DistanceUnit? // Track current unit to detect changes (initialized as nil)
    @State private var showSettings = false
    @State private var settingsAreaBeforeShow: RACountryArea? // Track area before showing settings
    @State private var settingsDateOptionBeforeShow: EventViewModel.SearchDateOption? // Track date option before showing settings
    @State private var settingsSortOptionBeforeShow: EventViewModel.SortOption? // Track sort option before showing settings
    @State private var showEventList = false // Control visibility of the side panel
    @State private var showingAreaPicker = false // Added state variable for area picker
    @State private var dragOffset: CGFloat = 0 // Track drag gesture offset
    @State private var showNearbyEvents = false // State for nearby mode
    
    // For 10 mile radius zoom level
    private let initialZoomMilesRadius: Double = 10.0
    private let locationService = LocationService.shared
    private let logger = AppLogger.shared
    private let osLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.whencetheraves", category: "EventMapView")
    
    // Location controller
    private var locationController: MapLocationController {
        MapLocationController(region: $region, locationService: locationService)
    }
    
    var body: some View {
        ZStack {
            MapViewRepresentable(
                region: $region,
                selectedEvent: $selectedEvent,
                showEventSheet: $showEventSheet,
                events: viewModel.events,
                showDistanceCircles: mapSettings.showDistanceCircles,
                distanceUnit: mapSettings.distanceUnit,
                onError: { errorMessage in
                    logger.error("Map error: \(errorMessage)")
                    mapError = errorMessage
                }
            )
            .id(forceMapRefresh)
            .ignoresSafeArea()
            .zIndex(0) // Base layer
            .onAppear {
                osLogger.debug("🗺 MapViewRepresentable initialized with zIndex: 0 (base layer)")
            }
            
            // Slide-in event list panel with tabs
            GeometryReader { geometry in
                let panelWidth = min(geometry.size.width * MapConstants.UI.Panel.maxWidthMultiplier, 
                                   MapConstants.UI.Panel.absoluteMaxWidth)
                
                let panelController = SlidePanelController(
                    panelWidth: panelWidth,
                    isVisible: $showEventList,
                    dragOffset: $dragOffset
                )
                
                HStack(spacing: 0) {
                    ZStack(alignment: .trailing) {
                        EventListPanelView(
                            viewModel: viewModel,
                            selectedEvent: $selectedEvent,
                            showEventSheet: $showEventSheet,
                            showEventList: $showEventList,
                            showNearbyEvents: $showNearbyEvents,
                            dragOffset: $dragOffset,
                            showingAreaPicker: $showingAreaPicker,
                            showSettings: $showSettings,
                            panelWidth: panelWidth,
                            distanceToEventLogic: locationController.distanceToEvent
                        )
                        .onAppear {
                            osLogger.debug("📱 EventListPanelView initialized with width: \(panelWidth)")
                            osLogger.debug("Panel z-index hierarchy: panel content < navigation tabs")
                        }
                        
                        // Navigation tabs on right edge
                        NavigationTabsView(
                            showEventList: $showEventList,
                            showNearbyEvents: $showNearbyEvents,
                            dragOffset: $dragOffset,
                            showSettings: $showSettings,
                            onLocationButtonTap: locationController.updateMapRegionToUserLocation
                        )
                        .offset(x: 40)
                        .zIndex(2) // Place above the panel but below other UI elements
                        .onAppear {
                            osLogger.debug("📱 NavigationTabsView initialized with zIndex: 2")
                            osLogger.debug("Navigation tabs positioned above panel content")
                        }
                    }
                    .offset(x: panelController.actualOffset)
                }
                .zIndex(1) // Place above map but below other UI elements
                .onAppear {
                    osLogger.debug("📱 Slide panel container initialized with zIndex: 1")
                }
            }
            
            // Top UI elements
                    VStack {
                // Top bar with title and settings button
                HStack {
                    AnimatedHeaderView(
                        showEventList: showEventList,
                        timePeriodText: getTimePeriodText()
                    )
                    
                    Spacer()
                }
                .padding(.horizontal)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                Spacer()
                        
                // Info overlay at the top right
                HStack {
                    Spacer()
                    
                        if let error = mapError {
                        Text("Error: \(error)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(8)
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                    }
                }
                
                // Bottom buttons
                HStack {
                    Spacer()
                    
                    VStack {
                        Text("\(viewModel.events.count) events")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(8)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.bottom, 8)
                        
                        // Location button removed as functionality exists elsewhere
                    }
                    .padding()
                }
                .padding(.bottom, 20) // Extra padding at bottom for safe area
                
                // Find events near me button when no area is selected
                if viewModel.events.isEmpty && viewModel.selectedArea == nil && !viewModel.isLoading {
                    VStack {
                Spacer()
                
                            Button {
                            logger.debug("Find events near me button tapped")
                            osLogger.debug("🔍 Find events near me button tapped")
                                viewModel.autoSelectNearestArea()
                            } label: {
                HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.white)
                                
                                Text("FIND EVENTS NEAR ME")
                                    .font(.system(.subheadline, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.pink, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                                    .cornerRadius(8)
                            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                        }
                        
                        Spacer().frame(height: 100) // Push up from the bottom
                    }
                }
            }
            .zIndex(3) // Top-level UI elements
            .onAppear {
                osLogger.debug("📱 Top UI elements initialized with zIndex: 3")
                osLogger.debug("Z-index hierarchy: map(0) < panel(1) < navTabs(2) < topUI(3)")
            }
            
            .sheet(isPresented: $showingAreaPicker) {
                AreaPickerView(selectedArea: $viewModel.selectedArea)
                    .presentationDetents([.medium, .large])
            }
            
            // Status overlays (loading, empty states)
            MapStatusOverlayView(
                viewModel: viewModel,
                onSelectLocationRequest: { showSettings = true }
            )
            .zIndex(4) // Above everything else
        }
        .sheet(isPresented: $showEventSheet) {
            if let event = selectedEvent {
                EventDetailView(event: event)
                    .presentationDetents([.medium, .large])
                    .onDisappear {
                        logger.debug("Event detail sheet closed for event: \(event.id) - \(event.title)")
                    }
            } else {
                // This should not happen, but log it if it does
                Text("Error: No event selected")
                    .onAppear {
                        logger.error("Attempted to show event detail sheet with no event selected")
                    }
            }
        }
        .sheet(isPresented: $showSettings, onDismiss: {
            // Check if any settings changed
            let areaChanged = settingsAreaBeforeShow?.id != viewModel.selectedArea?.id
            let dateOptionChanged = settingsDateOptionBeforeShow != viewModel.searchDate
            let sortOptionChanged = settingsSortOptionBeforeShow != viewModel.sortOption
            
            if areaChanged || dateOptionChanged || sortOptionChanged {
                logger.debug("Settings changed - triggering new search")
                
                if areaChanged {
                    logger.debug("Area changed from \(settingsAreaBeforeShow?.name ?? "nil") to \(viewModel.selectedArea?.name ?? "nil")")
                }
                
                if dateOptionChanged {
                    logger.debug("Date option changed from \(settingsDateOptionBeforeShow?.rawValue ?? "nil") to \(viewModel.searchDate.rawValue)")
                }
                
                if sortOptionChanged {
                    logger.debug("Sort option changed from \(settingsSortOptionBeforeShow?.rawValue ?? "nil") to \(viewModel.sortOption.rawValue)")
                }
                
                // Trigger a new search with the updated settings
                viewModel.findEvents()
            } else {
                logger.debug("No relevant settings changes detected")
            }
        }) {
            SettingsView(viewModel: viewModel)
                .onAppear {
                    // Save current values for comparison when sheet is dismissed
                    settingsAreaBeforeShow = viewModel.selectedArea
                    settingsDateOptionBeforeShow = viewModel.searchDate
                    settingsSortOptionBeforeShow = viewModel.sortOption
                    logger.debug("Settings view appeared - saved current values for comparison")
            }
        }
        .onAppear {
            osLogger.debug("📱 EventMapView appeared - Full z-index hierarchy:")
            osLogger.debug("0: MapViewRepresentable (base layer)")
            osLogger.debug("1: Slide Panel Container")
            osLogger.debug("2: Navigation Tabs")
            osLogger.debug("3: Top UI Elements")
            osLogger.debug("4: MapStatusOverlayView")
            osLogger.debug("Modal sheets and overlays: implicit top layer")
            
            logger.info("EventMapView appeared")
            
            // Initialize current unit for change tracking
            currentUnit = mapSettings.distanceUnit
            logger.debug("Initial distance unit: \(mapSettings.distanceUnit.rawValue)")
            
            locationController.debugEventsWithMissingLocations(viewModel.events)
            
            // Set initial zoom level to show a 10-mile radius around user's location
            if !initialLocationSet, let userLocation = locationService.currentLocation {
                initialLocationSet = true
                locationController.centerMapOnUserWithRadius(userLocation: userLocation, milesRadius: initialZoomMilesRadius)
            } else if !viewModel.events.isEmpty {
            // If we have events already loaded, update the map region
                logger.debug("Updating map to fit \(viewModel.events.count) events")
                locationController.updateMapRegionToFitEvents(viewModel.events)
            } else if locationService.currentLocation != nil {
                // Otherwise, center on user's location if available
                logger.debug("Centering map on user location")
                locationController.updateMapRegionToUserLocation()
                
                // If no area is selected, try to select the nearest area
                if viewModel.selectedArea == nil {
                    logger.debug("No area selected, attempting to select nearest area")
                    viewModel.autoSelectNearestArea()
                }
                
                // If no events are loaded, automatically search with the current settings
                if viewModel.events.isEmpty {
                    logger.debug("No events loaded, performing automatic search with default settings")
                    viewModel.findEvents()
                }
            } else {
                logger.debug("No user location available, using default map region")
                
                // If no events and no location, still try to auto-select area and search
                if viewModel.events.isEmpty {
                    viewModel.autoSelectNearestArea() 
                    // Use a delay to allow time for area selection
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if viewModel.selectedArea != nil && viewModel.events.isEmpty {
                            logger.debug("Performing delayed automatic search with default settings")
                            viewModel.findEvents()
                        }
                    }
                }
            }
        }
        // On location update, set initial map region if not done yet
        .onChange(of: locationService.currentLocation) { _, newLocation in
            if newLocation != nil && !initialLocationSet {
                initialLocationSet = true
                locationController.centerMapOnUserWithRadius(userLocation: newLocation!, milesRadius: initialZoomMilesRadius)
            }
        }
        // Update map when events change
        .onChange(of: viewModel.events) { oldEvents, newEvents in
            logger.debug("Events changed: \(oldEvents.count) -> \(newEvents.count)")
            locationController.debugEventsWithMissingLocations(newEvents)
            locationController.updateMapRegionToFitEvents(newEvents)
        }
        // Force immediate refresh when unit changes in settings
        .onReceive(mapSettings.$distanceUnit) { newUnit in
            osLogger.debug("🔍 MapSettings distanceUnit changed notification received: \(newUnit.rawValue)")
            
            // Only process if we've initialized currentUnit and it's different
            if let currentUnitValue = currentUnit, currentUnitValue != newUnit {
                osLogger.debug("🔍 Unit change detected: \(currentUnitValue.rawValue) -> \(newUnit.rawValue)")
                currentUnit = newUnit
                
                // Force a complete refresh of the map view
                DispatchQueue.main.async {
                    osLogger.debug("🔍 Forcing map refresh with new distance unit: \(newUnit.rawValue)")
                    osLogger.debug("🔍 Current forceMapRefresh value: \(forceMapRefresh)")
                    forceMapRefresh.toggle()
                    osLogger.debug("🔍 New forceMapRefresh value: \(forceMapRefresh)")
                }
            } else if currentUnit == nil {
                // Initialize if not yet set
                osLogger.debug("🔍 Initializing currentUnit to: \(newUnit.rawValue)")
                currentUnit = newUnit
            } else {
                osLogger.debug("🔍 No change in unit: already using \(newUnit.rawValue)")
            }
        }
        // Force immediate refresh when circle visibility changes
        .onReceive(mapSettings.$showDistanceCircles) { newValue in
            osLogger.debug("🔍 Show distance circles setting changed to \(newValue)")
            
            // Force a complete refresh of the map view
            DispatchQueue.main.async {
                osLogger.debug("🔍 Forcing map refresh due to circle visibility change")
                osLogger.debug("🔍 Current forceMapRefresh value: \(forceMapRefresh)")
                forceMapRefresh.toggle()
                osLogger.debug("🔍 New forceMapRefresh value: \(forceMapRefresh)")
            }
        }
        
        .onChange(of: forceMapRefresh) { _, newValue in
            osLogger.debug("🔍 forceMapRefresh changed to: \(newValue), which should trigger map rebuild")
        }
    }

    // Helper function to find nearby events
    private func findNearbyEvents() {
        guard locationService.currentLocation != nil else { 
            logger.warning("Cannot find nearby events: No user location available")
                return 
        }
        
        // If we have a current location, try to find the nearest area and search for events
        viewModel.autoSelectNearestArea()
        
        // Set to closest events sort option if available
        if !viewModel.sortOption.rawValue.contains("Distance") {
            for option in EventViewModel.SortOption.allCases {
                if option.rawValue.contains("Distance") {
                    viewModel.sortOption = option
                    break
                }
            }
        }
        
        // Find events with the current settings
        viewModel.findEvents()
    }
}

// MARK: - Helper Methods
extension EventMapView {
    // Helper function to format the time period text
    private func getTimePeriodText() -> String {
        let option = viewModel.searchDate
        let areaName = viewModel.selectedArea?.name ?? "Selected Area"
        
        switch option {
        case .today:
            return "Events today in \(areaName)"
        case .tomorrow:
            return "Events tomorrow in \(areaName)"
        case .week:
            return "Events this week in \(areaName)"
        case .twoWeeks:
            return "Events in next 14 days in \(areaName)"
        case .month:
            return "Events in next 30 days in \(areaName)"
        }
    }
} 