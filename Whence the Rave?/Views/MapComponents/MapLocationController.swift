import SwiftUI
import MapKit
import os.log
import Combine

/// Manages map location operations including region updates, user location handling, and distance calculations
class MapLocationController {
    // MARK: - Properties
    
    /// Current map region
    @Binding var region: MKCoordinateRegion
    
    /// Location service for accessing user location
    private let locationService: LocationService
    
    /// Logging
    private let logger = AppLogger.shared
    private let osLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.whencetheraves", category: "MapLocationController")
    
    // MARK: - Initialization
    
    init(region: Binding<MKCoordinateRegion>, locationService: LocationService = LocationService.shared) {
        self._region = region
        self.locationService = locationService
    }
    
    // MARK: - Public Methods
    
    /// Updates the map region to fit all provided events
    func updateMapRegionToFitEvents(_ events: [RAEvent]) {
        guard !events.isEmpty else { 
            logger.debug("Cannot update map region: No events")
            return 
        }
        
        // Check if we have user location first
        if let userLocation = locationService.currentLocation {
            // Instead of showing all events, show a reasonable area around the user
            // Use a maximum radius of 5 miles (or other suitable distance)
            let maxRadius = 5.0 // miles
            
            logger.debug("Keeping map centered on user location with \(maxRadius) mile radius instead of fitting all events")
            centerMapOnUserWithRadius(userLocation: userLocation, milesRadius: maxRadius)
            return
        }
        
        // Fall back to the old behavior if no user location is available
        var minLat: Double = 90.0
        var maxLat: Double = -90.0
        var minLon: Double = 180.0
        var maxLon: Double = -180.0
        
        var eventLocations = 0
        
        // Find the bounds of all event locations
        for event in events {
            if let venue = event.venue, let location = venue.location {
                minLat = min(minLat, location.latitude)
                maxLat = max(maxLat, location.latitude)
                minLon = min(minLon, location.longitude)
                maxLon = max(maxLon, location.longitude)
                eventLocations += 1
            }
        }
        
        logger.debug("Found \(eventLocations) mappable locations out of \(events.count) events")
        
        // If we have valid bounds
        if minLat < 90 && maxLat > -90 && minLon < 180 && maxLon > -180 {
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            
            // Calculate the span
            var latDelta = (maxLat - minLat) * 1.5
            var lonDelta = (maxLon - minLon) * 1.5
            
            // Limit the maximum zoom-out level
            let maxLatDelta = 0.5 // Limit to reasonable value, adjust as needed
            let maxLonDelta = 0.5 // About 30 miles across
            
            latDelta = min(latDelta, maxLatDelta)
            lonDelta = min(lonDelta, maxLonDelta)
            
            let span = MKCoordinateSpan(
                latitudeDelta: latDelta,
                longitudeDelta: lonDelta
            )
            
            logger.debug("Updated map region to center: \(center.latitude), \(center.longitude), span: \(span.latitudeDelta), \(span.longitudeDelta)")
            let newRegion = MKCoordinateRegion(center: center, span: span)
            region = newRegion
        } else {
            logger.warning("Invalid coordinate bounds for events: lat(\(minLat),\(maxLat)), lon(\(minLon),\(maxLon))")
        }
    }
    
    /// Updates the map region to center on the user's current location
    func updateMapRegionToUserLocation() {
        logger.debug("updateMapRegionToUserLocation() called")
        osLogger.debug("🔍 updateMapRegionToUserLocation() called")
        
        if let location = locationService.currentLocation {
            logger.debug("Setting map region to user location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            osLogger.debug("🔍 Setting map region to user location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        } else {
            logger.warning("Cannot set map to user location: No location available")
            osLogger.debug("⚠️ Cannot set map to user location: No location available")
        }
    }
    
    /// Centers the map on user with a specific radius in miles
    func centerMapOnUserWithRadius(userLocation: CLLocation, milesRadius: Double) {
        // Convert miles to latitude degrees (approximate)
        // 1 degree of latitude is approximately 69 miles
        let latDelta = milesRadius / 69.0
        
        // Convert miles to longitude degrees (this varies by latitude)
        // At the equator, 1 degree of longitude is approximately 69 miles
        // At other latitudes, it's approximately 69 * cos(latitude in radians)
        let userLatRadians = userLocation.coordinate.latitude * .pi / 180
        let lonDelta = milesRadius / (69.0 * cos(userLatRadians))
        
        // Create a region that shows the desired radius
        let span = MKCoordinateSpan(latitudeDelta: latDelta * 2.0, longitudeDelta: lonDelta * 2.0)
        let newRegion = MKCoordinateRegion(center: userLocation.coordinate, span: span)
        
        logger.info("Setting initial map region to show \(milesRadius) mile radius around user location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
        logger.debug("Calculated span for \(milesRadius) mile radius: lat delta = \(span.latitudeDelta), lon delta = \(span.longitudeDelta)")
        
        region = newRegion
    }
    
    /// Calculates the distance from user location to event
    func distanceToEvent(_ event: RAEvent) -> Double {
        guard let userLocation = locationService.currentLocation,
              let venue = event.venue,
              let location = venue.location else {
            return Double.infinity
        }
        
        let eventLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return userLocation.distance(from: eventLocation)
    }
    
    /// Debug function to log events with missing location data
    func debugEventsWithMissingLocations(_ events: [RAEvent]) {
        let totalEvents = events.count
        let mappableEvents = events.filter { event in
            event.venue != nil && event.venue?.location != nil
        }.count
        
        logger.info("Total events: \(totalEvents), Mappable events: \(mappableEvents)")
        
        if totalEvents > mappableEvents {
            logger.warning("Events missing location data (\(totalEvents - mappableEvents)):")
            for (index, event) in events.enumerated() {
                if event.venue == nil {
                    logger.warning("[\(index)] \(event.title): No venue data")
                } else if event.venue?.location == nil {
                    logger.warning("[\(index)] \(event.title): Venue \(event.venue?.name ?? "unknown") has no location")
                    
                    // Additional venue debugging
                    if let venue = event.venue {
                        logger.debug("Venue details for \(event.title): id=\(venue.id), area=\(venue.area?.name ?? "none"), address=\(venue.address ?? "none")")
                    }
                }
            }
        }
    }
} 