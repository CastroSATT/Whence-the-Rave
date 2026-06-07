import SwiftUI
import MapKit
import os.log

enum MapNavigationMode {
    case free
    case following
}

/// Single owner of map camera and navigation mode (LOC / FOL).
final class MapNavigationController: ObservableObject {
    @Published private(set) var region: MKCoordinateRegion
    @Published private(set) var navigationMode: MapNavigationMode = .free

    private var pendingRegion: MKCoordinateRegion?
    private var hasAppliedInitialRegion = false
    private(set) var hasUserMovedMap = false

    private let locationService: LocationService
    private let logger = AppLogger.shared
    private let osLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.whencetheraves", category: "MapNavigationController")

    var isFollowingUser: Bool { navigationMode == .following }

    init(
        locationService: LocationService = .shared,
        defaultRegion: MKCoordinateRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.5074, longitude: 0.1278),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    ) {
        self.locationService = locationService
        self.region = defaultRegion
        locationService.startHeadingUpdates()
    }

    // MARK: - Public API

    func applyInitialRegionIfNeeded(userLocation: CLLocation, milesRadius: Double) {
        guard !hasAppliedInitialRegion else { return }
        hasAppliedInitialRegion = true
        logger.debug("Applying one-time initial map region (\(milesRadius) mile radius)")
        queueRegion(regionForUser(userLocation, milesRadius: milesRadius))
    }

    @discardableResult
    func centerOnUser(preserveZoom: Bool = true) -> Bool {
        guard let location = locationService.currentLocation else {
            logger.warning("Cannot center on user: No location available")
            return false
        }
        navigationMode = .free
        let span = preserveZoom ? region.span : spanForMilesRadius(10, at: location.coordinate.latitude)
        queueRegion(MKCoordinateRegion(center: location.coordinate, span: span))
        return true
    }

    @discardableResult
    func enableFollowMode() -> Bool {
        guard locationService.currentLocation != nil else {
            logger.warning("Cannot enable follow mode: No location available")
            return false
        }
        pendingRegion = nil
        navigationMode = .following
        osLogger.debug("Follow mode enabled")
        return true
    }

    func centerOnCoordinate(
        _ coordinate: CLLocationCoordinate2D,
        span: MKCoordinateSpan,
        latitudeOffsetFraction: Double = 0.25
    ) {
        let latitudeOffset = span.latitudeDelta * latitudeOffsetFraction
        let offsetCenter = CLLocationCoordinate2D(
            latitude: coordinate.latitude - latitudeOffset,
            longitude: coordinate.longitude
        )
        queueRegion(MKCoordinateRegion(center: offsetCenter, span: span))
    }

    func userDidPan(to mapRegion: MKCoordinateRegion) {
        pendingRegion = nil
        hasUserMovedMap = true
        region = mapRegion
    }

    func syncRegionFromMap(_ mapRegion: MKCoordinateRegion) {
        region = mapRegion
    }

    func followModeDisabledByMapKit(at mapRegion: MKCoordinateRegion) {
        guard navigationMode == .following else { return }
        navigationMode = .free
        hasUserMovedMap = true
        pendingRegion = nil
        region = mapRegion
        osLogger.debug("Follow mode disabled by map interaction")
    }

    func consumePendingRegion() -> MKCoordinateRegion? {
        let pending = pendingRegion
        pendingRegion = nil
        return pending
    }

    func markProgrammaticRegionApplied(_ appliedRegion: MKCoordinateRegion) {
        region = appliedRegion
    }

    func clearPendingRegion() {
        pendingRegion = nil
    }

    // MARK: - Distance utilities

    func distanceToEvent(_ event: RAEvent) -> Double {
        guard let userLocation = locationService.currentLocation,
              let venue = event.venue,
              let location = venue.location else {
            return Double.infinity
        }
        let eventLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return userLocation.distance(from: eventLocation)
    }

    func debugEventsWithMissingLocations(_ events: [RAEvent]) {
        let totalEvents = events.count
        let mappableEvents = events.filter { $0.venue?.location != nil }.count
        logger.info("Total events: \(totalEvents), Mappable events: \(mappableEvents)")

        if totalEvents > mappableEvents {
            logger.warning("Events missing location data (\(totalEvents - mappableEvents)):")
            for (index, event) in events.enumerated() {
                if event.venue == nil {
                    logger.warning("[\(index)] \(event.title): No venue data")
                } else if event.venue?.location == nil {
                    logger.warning("[\(index)] \(event.title): Venue \(event.venue?.name ?? "unknown") has no location")
                }
            }
        }
    }

    // MARK: - Region helpers

    static func regionsAreApproximatelyEqual(_ a: MKCoordinateRegion, _ b: MKCoordinateRegion, epsilon: Double = 0.00001) -> Bool {
        abs(a.center.latitude - b.center.latitude) < epsilon
            && abs(a.center.longitude - b.center.longitude) < epsilon
            && abs(a.span.latitudeDelta - b.span.latitudeDelta) < epsilon
            && abs(a.span.longitudeDelta - b.span.longitudeDelta) < epsilon
    }

    private func queueRegion(_ newRegion: MKCoordinateRegion) {
        pendingRegion = newRegion
        objectWillChange.send()
    }

    private func regionForUser(_ userLocation: CLLocation, milesRadius: Double) -> MKCoordinateRegion {
        let span = spanForMilesRadius(milesRadius, at: userLocation.coordinate.latitude)
        return MKCoordinateRegion(center: userLocation.coordinate, span: span)
    }

    private func spanForMilesRadius(_ milesRadius: Double, at latitude: Double) -> MKCoordinateSpan {
        let latDelta = milesRadius / 69.0
        let latRadians = latitude * .pi / 180
        let lonDelta = milesRadius / (69.0 * cos(latRadians))
        return MKCoordinateSpan(latitudeDelta: latDelta * 2.0, longitudeDelta: lonDelta * 2.0)
    }
}
