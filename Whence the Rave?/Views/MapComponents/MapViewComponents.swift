import SwiftUI
import MapKit
import os.log

// Custom annotation class for events
class EventAnnotation: NSObject, MKAnnotation {
    public let coordinate: CLLocationCoordinate2D
    public let title: String?
    public let subtitle: String?
    let event: RAEvent
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, event: RAEvent) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.event = event
        super.init()
    }
}

// Custom annotation class for distance labels
class DistanceLabelAnnotation: NSObject, MKAnnotation {
    public let coordinate: CLLocationCoordinate2D
    public let title: String?
    public let subtitle: String?
    let circleType: CircleType
    
    init(coordinate: CLLocationCoordinate2D, distance: String, circleType: CircleType) {
        self.coordinate = coordinate
        self.title = distance
        self.subtitle = nil
        self.circleType = circleType
        super.init()
    }
}

// Circle types for distance indicators
enum CircleType {
    case small
    case medium
    case large
}

// UIViewRepresentable that bridges to MKMapView
struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedEvent: RAEvent?
    @Binding var showEventSheet: Bool
    let events: [RAEvent]
    let showDistanceCircles: Bool
    let distanceUnit: DistanceUnit
    var onError: ((String) -> Void)?
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.whencetheraves", category: "MapView")
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.whencetheraves", category: "MapViewCoordinator")
        private var distanceOverlays: [MKCircle] = []
        var isAnnotationSelected = false
        var lastSelectedAnnotation: EventAnnotation?
        var annotationSelectionTimestamp: TimeInterval = 0
        // Dictionary to track circle types
        private var circleTypeMap: [MKCircle: CircleType] = [:]
        
        init(parent: MapViewRepresentable) {
            self.parent = parent
            super.init()
            logger.debug("Map coordinator initialized")
        }
        
        public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Skip for user location annotation
            if annotation is MKUserLocation {
                logger.debug("Skipping view creation for user location annotation")
                return nil
            }
            
            // Check if this is a distance label annotation
            if let labelAnnotation = annotation as? DistanceLabelAnnotation {
                let identifier = "DistanceLabel"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: labelAnnotation, reuseIdentifier: identifier)
                    
                    // Create a background for the text
                    let label = UILabel()
                    label.text = labelAnnotation.title
                    label.textColor = .white
                    label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
                    
                    // Set color based on circle type - consistent colors regardless of radius
                    switch labelAnnotation.circleType {
                    case .small:
                        label.backgroundColor = UIColor(red: 85/255, green: 187/255, blue: 85/255, alpha: 0.8) // Green
                    case .medium:
                        label.backgroundColor = UIColor(red: 240/255, green: 196/255, blue: 67/255, alpha: 0.8) // Amber
                    case .large:
                        label.backgroundColor = UIColor(red: 240/255, green: 128/255, blue: 128/255, alpha: 0.8) // Red
                    }
                    
                    label.textAlignment = .center
                    label.layer.cornerRadius = 8
                    label.layer.masksToBounds = true
                    label.sizeToFit()
                    
                    // Add padding
                    let padding: CGFloat = 4
                    let paddedFrame = CGRect(
                        x: -padding,
                        y: -padding,
                        width: label.frame.width + (padding * 2),
                        height: label.frame.height + (padding * 2)
                    )
                    label.frame = paddedFrame
                    
                    annotationView?.addSubview(label)
                    annotationView?.frame = label.frame
                    
                    // Center the label
                    annotationView?.centerOffset = CGPoint(x: 0, y: -annotationView!.frame.height / 2)
                } else {
                    annotationView?.annotation = labelAnnotation
                    
                    // Update label if reusing an existing view
                    if let label = annotationView?.subviews.first as? UILabel {
                        // Update the label text
                        label.text = labelAnnotation.title
                        
                        // Set color based on circle type - consistent colors regardless of radius
                        switch labelAnnotation.circleType {
                        case .small:
                            label.backgroundColor = UIColor(red: 85/255, green: 187/255, blue: 85/255, alpha: 0.8) // Green
                        case .medium:
                            label.backgroundColor = UIColor(red: 240/255, green: 196/255, blue: 67/255, alpha: 0.8) // Amber
                        case .large:
                            label.backgroundColor = UIColor(red: 240/255, green: 128/255, blue: 128/255, alpha: 0.8) // Red
                        }
                    }
                }
                
                return annotationView
            }
            
            // Handle event annotations
            guard let annotation = annotation as? EventAnnotation else { 
                logger.warning("Unknown annotation type: \(type(of: annotation))")
                return nil 
            }
            
            let identifier = "EventMarker"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            let eventId = annotation.event.id
            let eventTitle = annotation.event.title
            
            if annotationView == nil {
                logger.debug("Creating new annotation view for event '\(eventTitle)' (id: \(eventId))")
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false // Disable callout since we're showing detail view directly
                
                // Make pins easier to tap
                annotationView?.collisionMode = .circle
                annotationView?.isEnabled = true
                
                // Increase the tap target area
                if let markerView = annotationView {
                    // Ensure map annotations have sufficient padding for taps
                    // Color based on popularity
                    let interestedCount = annotation.event.interestedCount
                    
                    if interestedCount >= 500 {
                        markerView.markerTintColor = UIColor.systemRed
                    } else if interestedCount >= 100 {
                        markerView.markerTintColor = UIColor.systemOrange
                    } else {
                    markerView.markerTintColor = UIColor.systemBlue
                    }
                    
                    markerView.glyphTintColor = UIColor.white
                    markerView.glyphImage = UIImage(systemName: "music.note")
                    
                    // Use a custom subclass if we need to expand the hit test area
                    // For now, just ensure the marker is responsive
                    markerView.isUserInteractionEnabled = true
                }
                
                logger.debug("Setting collisionMode=.circle and isEnabled=true for event '\(eventTitle)'")
                
                // Ensure pins are always visible
                annotationView?.displayPriority = .required
                annotationView?.zPriority = .max
                annotationView?.clusteringIdentifier = nil // Disable clustering
                logger.debug("Set pin visibility properties: displayPriority=.required, zPriority=.max for '\(eventTitle)'")
            } else {
                logger.debug("Reusing annotation view for '\(eventTitle)' (id: \(eventId))")
                annotationView?.annotation = annotation
                
                // Ensure reused annotation view has proper configuration
                annotationView?.displayPriority = .required
                annotationView?.zPriority = .max
                annotationView?.canShowCallout = false
                logger.debug("Reset display properties on reused pin for '\(eventTitle)'")
                
                // Update marker color based on popularity
            if let markerView = annotationView {
                let interestedCount = annotation.event.interestedCount
                
                if interestedCount >= 500 {
                    markerView.markerTintColor = UIColor.systemRed
                } else if interestedCount >= 100 {
                    markerView.markerTintColor = UIColor.systemOrange
                } else {
                    markerView.markerTintColor = UIColor.systemBlue
                }
                }
            }
            
            return annotationView
        }
        
        public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circle = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circle)
                
                // Style based on the circle's type from our map
                if let circleType = circleTypeMap[circle] {
                    switch circleType {
                    case .small:
                        // Inner circle - pastel green
                        renderer.fillColor = UIColor(red: 144/255, green: 238/255, blue: 144/255, alpha: 0.15)
                        renderer.strokeColor = UIColor(red: 85/255, green: 187/255, blue: 85/255, alpha: 0.8)
                        renderer.lineWidth = 1.0
                    
                    case .medium:
                        // Middle circle - pastel yellow/amber
                        renderer.fillColor = UIColor(red: 255/255, green: 236/255, blue: 139/255, alpha: 0.15)
                        renderer.strokeColor = UIColor(red: 240/255, green: 196/255, blue: 67/255, alpha: 0.8)
                        renderer.lineWidth = 1.0
                    
                    case .large:
                        // Outer circle - pastel red
                        renderer.fillColor = UIColor(red: 255/255, green: 182/255, blue: 193/255, alpha: 0.15)
                        renderer.strokeColor = UIColor(red: 240/255, green: 128/255, blue: 128/255, alpha: 0.8)
                        renderer.lineWidth = 1.0
                    }
                } else {
                    // Default fallback
                    renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.1)
                    renderer.strokeColor = UIColor.systemBlue
                    renderer.lineWidth = 1.0
                }
                
                return renderer
            }
            
            return MKOverlayRenderer(overlay: overlay)
        }
        
        public func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
            logger.error("Failed to locate user: \(error.localizedDescription)")
            parent.onError?("Failed to locate user: \(error.localizedDescription)")
        }
        
        public func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
            logger.debug("Map finished loading")
            
            // Debug existing annotations
            let eventAnnotationCount = mapView.annotations.filter { $0 is EventAnnotation }.count
            let userLocationAnnotationCount = mapView.annotations.filter { $0 is MKUserLocation }.count
            let distanceLabelCount = mapView.annotations.filter { $0 is DistanceLabelAnnotation }.count
            let otherAnnotationCount = mapView.annotations.filter { 
                !($0 is EventAnnotation) && !($0 is MKUserLocation) && !($0 is DistanceLabelAnnotation) 
            }.count
            
            logger.debug("Annotation counts - Event: \(eventAnnotationCount), User: \(userLocationAnnotationCount), Distance: \(distanceLabelCount), Other: \(otherAnnotationCount)")
        }
        
        public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? EventAnnotation else { 
                logger.debug("Selected non-event annotation: \(type(of: view.annotation ?? MKPointAnnotation()))")
                return 
            }
            
            let currentTime = Date().timeIntervalSince1970
            let eventTitle = annotation.event.title
            let eventId = annotation.event.id
            
            logger.debug("Selected annotation for event: '\(eventTitle)' (id: \(eventId))")
            
            // Skip the callout and directly show the event detail sheet
            parent.selectedEvent = annotation.event
            isAnnotationSelected = true
            lastSelectedAnnotation = annotation
            annotationSelectionTimestamp = currentTime
            
            // Immediately show the event detail view
            parent.showEventSheet = true
            
            // Deselect the annotation to prevent callout issues
            mapView.deselectAnnotation(annotation, animated: false)
        }
        
        public func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            if let annotation = view.annotation as? EventAnnotation {
                logger.debug("Deselected annotation for event: '\(annotation.event.title)' (id: \(annotation.event.id))")
            } else {
                logger.debug("Deselected unknown annotation: \(type(of: view.annotation ?? MKPointAnnotation()))")
            }
            
            // Reset selection flag after a short delay to allow for tapping the callout accessory
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isAnnotationSelected = false
                self.logger.debug("Reset isAnnotationSelected flag to false")
            }
        }
        
        public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            logger.debug("Map region changed to: \(mapView.region.center.latitude), \(mapView.region.center.longitude), span: \(mapView.region.span.latitudeDelta), \(mapView.region.span.longitudeDelta)")
            logger.debug("isAnnotationSelected during region change: \(self.isAnnotationSelected)")
            
            // If an annotation is selected, don't update parent's region to prevent jumps
            if !self.isAnnotationSelected {
                // Only update the parent region if the change wasn't due to annotation selection
                parent.region = mapView.region
                logger.debug("Updated parent region to match map's current region")
            } else {
                logger.debug("Skipped updating parent region due to annotation selection")
            }
        }
        
        // Add distance circles centered at user location
        public func updateDistanceCircles(on mapView: MKMapView, userLocation: CLLocationCoordinate2D?) {
            // Remove existing circles
            if !distanceOverlays.isEmpty {
                mapView.removeOverlays(distanceOverlays)
                distanceOverlays.removeAll()
                circleTypeMap.removeAll() // Clear the circle type map
            }
            
            // Remove existing distance label annotations
            let existingLabelAnnotations = mapView.annotations.filter { $0 is DistanceLabelAnnotation }
            if !existingLabelAnnotations.isEmpty {
                mapView.removeAnnotations(existingLabelAnnotations)
            }
            
            guard let userLocation = userLocation else {
                logger.debug("Cannot add distance circles: No user location")
                return
            }
            
            // Log current unit for debugging
            logger.debug("🔵 Adding distance circles using unit: \(self.parent.distanceUnit.rawValue)")
            logger.debug("🔵 Distance circles around user location: \(userLocation.latitude), \(userLocation.longitude)")
            
            // Set radii based on the selected unit (in meters)
            let unit = self.parent.distanceUnit
            var radiusSmall: Double
            var radiusMedium: Double
            var radiusLarge: Double
            
            switch unit {
            case .kilometers:
                // Round kilometer values
                radiusSmall = 1000     // 1km
                radiusMedium = 3000    // 3km
                radiusLarge = 5000     // 5km
            case .meters:
                // Round meter values
                radiusSmall = 500      // 500m
                radiusMedium = 1000    // 1000m
                radiusLarge = 2000     // 2000m
            case .miles:
                // Round mile values converted to meters
                radiusSmall = 1609.34  // 1 mile
                radiusMedium = 4828.03 // 3 miles
                radiusLarge = 8046.72  // 5 miles
            }
            
            // Create circles with appropriate radii
            let smallCircle = MKCircle(center: userLocation, radius: radiusSmall)
            let mediumCircle = MKCircle(center: userLocation, radius: radiusMedium)
            let largeCircle = MKCircle(center: userLocation, radius: radiusLarge)
            
            // Track the circle types
            circleTypeMap[smallCircle] = .small
            circleTypeMap[mediumCircle] = .medium
            circleTypeMap[largeCircle] = .large
            
            // Set the actual distances for display in labels - round to nice values
            let smallDistance: Double
            let mediumDistance: Double
            let largeDistance: Double
            
            switch unit {
            case .kilometers:
                smallDistance = 1.0  // 1km
                mediumDistance = 3.0 // 3km
                largeDistance = 5.0  // 5km
            case .meters:
                smallDistance = 500   // 500m
                mediumDistance = 1000 // 1000m
                largeDistance = 2000  // 2000m
            case .miles:
                smallDistance = 1.0  // 1mi
                mediumDistance = 3.0 // 3mi
                largeDistance = 5.0  // 5mi
            }
            
            // Format labels with clean, round numbers
            let smallLabel = formatDistance(smallDistance, unit: unit)
            let mediumLabel = formatDistance(mediumDistance, unit: unit)
            let largeLabel = formatDistance(largeDistance, unit: unit)
            
            // Add the circles to the map
            distanceOverlays = [smallCircle, mediumCircle, largeCircle]
            mapView.addOverlays(distanceOverlays)
            
            // Calculate position for labels (north of the user location)
            let smallLabelCoord = calculateCoordinate(from: userLocation, atDistanceMeters: radiusSmall, bearingDegrees: 0)
            let mediumLabelCoord = calculateCoordinate(from: userLocation, atDistanceMeters: radiusMedium, bearingDegrees: 0)
            let largeLabelCoord = calculateCoordinate(from: userLocation, atDistanceMeters: radiusLarge, bearingDegrees: 0)
            
            // Create label annotations with appropriate types
            let smallAnnotation = DistanceLabelAnnotation(coordinate: smallLabelCoord, distance: smallLabel, circleType: .small)
            let mediumAnnotation = DistanceLabelAnnotation(coordinate: mediumLabelCoord, distance: mediumLabel, circleType: .medium)
            let largeAnnotation = DistanceLabelAnnotation(coordinate: largeLabelCoord, distance: largeLabel, circleType: .large)
            
            // Add labels to map
            mapView.addAnnotations([smallAnnotation, mediumAnnotation, largeAnnotation])
            
            logger.debug("Added distance circles with labels: \(smallLabel) (green), \(mediumLabel) (amber), \(largeLabel) (red)")
        }
        
        // Helper function to format distances with clean round numbers
        private func formatDistance(_ distance: Double, unit: DistanceUnit) -> String {
            switch unit {
            case .kilometers:
                return String(format: "%.1f km", distance)
            case .meters:
                return String(format: "%.0f m", distance)
            case .miles:
                return String(format: "%.1f mi", distance)
            }
        }
        
        // Calculate a coordinate at a given distance and bearing from a point
        private func calculateCoordinate(from coordinate: CLLocationCoordinate2D, atDistanceMeters distance: Double, bearingDegrees: Double) -> CLLocationCoordinate2D {
            let earthRadiusMeters = 6371000.0 // Earth's radius in meters
            let distanceRadians = distance / earthRadiusMeters
            let bearingRadians = bearingDegrees * .pi / 180.0
            let fromLatRadians = coordinate.latitude * .pi / 180.0
            let fromLonRadians = coordinate.longitude * .pi / 180.0
            
            let toLatRadians = asin(sin(fromLatRadians) * cos(distanceRadians) + 
                              cos(fromLatRadians) * sin(distanceRadians) * cos(bearingRadians))
            
            var toLonRadians = fromLonRadians + atan2(sin(bearingRadians) * sin(distanceRadians) * cos(fromLatRadians),
                                                 cos(distanceRadians) - sin(fromLatRadians) * sin(toLatRadians))
            
            // Normalize longitude to -180...+180
            toLonRadians = fmod((toLonRadians + 3 * .pi), (2 * .pi)) - .pi
            
            return CLLocationCoordinate2D(
                latitude: toLatRadians * 180.0 / .pi,
                longitude: toLonRadians * 180.0 / .pi
            )
        }
        
        // For debugging annotation views
        public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
            for view in views {
                if let eventAnnotation = view.annotation as? EventAnnotation {
                    let eventTitle = eventAnnotation.event.title
                    let eventId = eventAnnotation.event.id
                    
                    // Log z-position details for each annotation view as it's added
                    logger.debug("Added annotation view for '\(eventTitle)' (id: \(eventId)): frame=\(view.frame.debugDescription), zPos=\(view.layer.zPosition)")
                    
                    // Check for overlapping annotations
                    let overlappingViews = views.filter { otherView in
                        guard otherView != view, 
                              let otherAnnotation = otherView.annotation as? EventAnnotation,
                              otherAnnotation.event.id != eventAnnotation.event.id else { 
                            return false 
                        }
                        
                        // Check if frames overlap (potential selection issue)
                        return view.frame.intersects(otherView.frame)
                    }
                    
                    if !overlappingViews.isEmpty {
                        let overlappingTitles = overlappingViews.compactMap { ($0.annotation as? EventAnnotation)?.event.title }
                        logger.warning("❗️ Annotation for '\(eventTitle)' overlaps with: \(overlappingTitles.joined(separator: ", "))")
                        
                        // Adjust z-position for overlapping annotations to ensure proper selection order
                        view.layer.zPosition = 1100
                        logger.debug("Raised z-position to \(view.layer.zPosition) due to overlap")
                    }
                }
            }
        }
    }
    
    init(region: Binding<MKCoordinateRegion>, 
                selectedEvent: Binding<RAEvent?>, 
                showEventSheet: Binding<Bool>, 
                events: [RAEvent], 
                showDistanceCircles: Bool, 
                distanceUnit: DistanceUnit, 
                onError: ((String) -> Void)? = nil) {
        self._region = region
        self._selectedEvent = selectedEvent
        self._showEventSheet = showEventSheet
        self.events = events
        self.showDistanceCircles = showDistanceCircles
        self.distanceUnit = distanceUnit
        self.onError = onError
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        logger.debug("Creating MKMapView")
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.showsUserLocation = true
        
        // Configure the map to prioritize showing all pins
        mapView.preferredConfiguration = MKStandardMapConfiguration()
        
        // Show compass in the top right
        mapView.showsCompass = true
        
        // Register reusable annotation views
        mapView.register(
            MKMarkerAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: "EventMarker"
        )
        
        // Disable selection of user location annotation
        if let userLocationView = mapView.view(for: mapView.userLocation) {
            userLocationView.isEnabled = false
        }
        
        // Additional settings to improve annotation interaction
        mapView.selectableMapFeatures = []  // Disable selection of map features like POIs
        
        // Set this to ensure pins are responsive to taps
        mapView.isPitchEnabled = false // Disabling 3D view can make pins easier to tap
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        logger.debug("Updating MKMapView: \(events.count) events, region: \(region.center.latitude), \(region.center.longitude)")
        
        // Only update the map region if this is not triggered by user selecting an annotation
        if !context.coordinator.isAnnotationSelected {
            // Use a non-animated update to prevent jumps
            uiView.setRegion(region, animated: false)
        }
        
        // Position the compass in the top right corner
        // This needs to be done here because we need the frame to be set
        if let compassView = uiView.subviews.first(where: { $0 is MKCompassButton }) {
            compassView.frame.origin = CGPoint(x: uiView.frame.width - compassView.frame.width - 10, y: 50)
        }
        
        // Smart annotation management - only update annotations when necessary
        let existingEventAnnotations = uiView.annotations.compactMap { $0 as? EventAnnotation }
        let existingEventIds = Set(existingEventAnnotations.map { $0.event.id })
        let newEventIds = Set(events.map { $0.id })
        
        // Check if annotations need to be updated
        let annotationsNeedUpdate = existingEventAnnotations.count != events.count || 
                                   !existingEventIds.isSuperset(of: newEventIds) || 
                                   !newEventIds.isSuperset(of: existingEventIds)
        
        logger.debug("Annotations check: existingCount=\(existingEventAnnotations.count), newCount=\(events.count), needsUpdate=\(annotationsNeedUpdate)")
        
        if annotationsNeedUpdate {
            logger.debug("Annotation sets differ - updating annotations")
            logger.debug("Existing IDs count: \(existingEventIds.count), New IDs count: \(newEventIds.count)")
            
            // Preserve selection state
            var selectedEventId: String? = nil
            for annotation in uiView.selectedAnnotations {
                if let eventAnnotation = annotation as? EventAnnotation {
                    selectedEventId = eventAnnotation.event.id
                    break
                }
            }
            
            // Find annotations to remove (exist on map but not in new data)
            let annotationsToRemove = existingEventAnnotations.filter { !newEventIds.contains($0.event.id) }
            if !annotationsToRemove.isEmpty {
                logger.debug("Removing \(annotationsToRemove.count) outdated annotations")
                uiView.removeAnnotations(annotationsToRemove)
            }
            
            // Find events to add (in new data but not on map)
            let eventIdsToAdd = newEventIds.subtracting(existingEventIds)
            let eventsToAdd = events.filter { eventIdsToAdd.contains($0.id) }
            
            if !eventsToAdd.isEmpty {
                logger.debug("Adding \(eventsToAdd.count) new annotations")
                
                // Create annotations for new events
                let newAnnotations = eventsToAdd.compactMap { event -> EventAnnotation? in
                    guard let venue = event.venue, let location = venue.location else { 
                        logger.warning("Cannot add annotation for event '\(event.title)': missing venue or location data")
                        return nil 
                    }
                    
                    // Check if we already have annotations at or very near this location
                    let coordinate = CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    )
                    
                    // Apply a small jitter to prevent perfect overlapping of pins at the same venue
                    let jitteredCoordinate = applyJitterToCoordinate(
                        coordinate: coordinate,
                        existingAnnotations: existingEventAnnotations
                    )
                    
                    return EventAnnotation(
                        coordinate: jitteredCoordinate,
                        title: event.title,
                        subtitle: venue.name,
                        event: event
                    )
                }
                
                if !newAnnotations.isEmpty {
                    logger.debug("Adding \(newAnnotations.count) new annotation views to map")
                    uiView.addAnnotations(newAnnotations)
                }
            }
            
            // Re-select previously selected annotation if it exists in new annotations
            if let eventId = selectedEventId,
               let newAnnotation = uiView.annotations.compactMap({ $0 as? EventAnnotation }).first(where: { $0.event.id == eventId }) {
                uiView.selectAnnotation(newAnnotation, animated: false)
                logger.debug("Re-selected annotation for '\(newAnnotation.event.title)'")
            }
        } else {
            logger.debug("No annotation updates needed - same events with same IDs")
        }
        
        // Update distance circles if user location is available and they should be shown
        if showDistanceCircles, let userLocation = LocationService.shared.currentLocation?.coordinate {
            context.coordinator.updateDistanceCircles(on: uiView, userLocation: userLocation)
        } else if !showDistanceCircles {
            // Remove distance circles if they should be hidden
            context.coordinator.updateDistanceCircles(on: uiView, userLocation: nil)
        }
        
        // Reset the annotation selection flag after update
        if context.coordinator.isAnnotationSelected {
            context.coordinator.isAnnotationSelected = false
        }
    }
    
    // Add this function to help distribute pins at the same venue
    private func applyJitterToCoordinate(coordinate: CLLocationCoordinate2D, existingAnnotations: [EventAnnotation]) -> CLLocationCoordinate2D {
        // Check if there are existing annotations close to this coordinate
        let closeAnnotations = existingAnnotations.filter { annotation in
            let distance = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                .distance(from: CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude))
            return distance < 20 // Less than 20 meters apart is considered the "same location"
        }
        
        // If no close pins, return the original coordinate
        if closeAnnotations.isEmpty {
            return coordinate
        }
        
        // Apply a radial jitter around the original point
        // The more pins we have, the larger the radius needed
        let jitterRadius = min(0.0001 * Double(closeAnnotations.count + 1), 0.0005) // Max ~50m away
        let angle = Double.random(in: 0..<(2 * .pi)) // Random angle in radians
        let jitterDistance = Double.random(in: 0.3..<1.0) * jitterRadius // Variable distance
        
        // Calculate offset
        let latOffset = jitterDistance * cos(angle)
        let lonOffset = jitterDistance * sin(angle)
        
        // Apply offset
        return CLLocationCoordinate2D(
            latitude: coordinate.latitude + latOffset,
            longitude: coordinate.longitude + lonOffset
        )
    }
} 