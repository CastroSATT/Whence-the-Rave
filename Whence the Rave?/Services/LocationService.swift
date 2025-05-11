import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private let logger = AppLogger.shared
    
    @Published var currentLocation: CLLocation?
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var countries: [RACountry] = []
    @Published var isLoadingAreas: Bool = false
    @Published var loadingError: Error?
    @Published var nearestArea: RACountryArea?
    
    private override init() {
        super.init()
        logger.info("LocationService initialized")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Load countries from cache or server
        loadCountriesDatabase()
    }
    
    func requestLocationPermission() {
        logger.info("Requesting location permission")
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        logger.info("Starting location updates")
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        logger.info("Stopping location updates")
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Area Database Management
    
    func loadCountriesDatabase(forceRefresh: Bool = false) {
        logger.info("Loading countries database (forceRefresh: \(forceRefresh))")
        isLoadingAreas = true
        loadingError = nil
        
        // If not forcing refresh, try to load from local cache first
        if !forceRefresh, let cachedCountries = loadCountriesFromCache() {
            logger.info("Successfully loaded \(cachedCountries.count) countries from cache")
            self.countries = cachedCountries
            self.isLoadingAreas = false
            return
        }
        
        // Otherwise, always fetch from server
        logger.info(forceRefresh ? "Force refreshing from API" : "No valid cache found, fetching countries from server")
        fetchCountriesFromServer(forceRefresh: forceRefresh)
    }
    
    private func loadCountriesFromCache() -> [RACountry]? {
        guard let url = getCountriesCacheUrl() else {
            logger.warning("Failed to get cache URL for countries data")
            return nil
        }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            logger.info("Countries cache file doesn't exist")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            logger.debug("Read \(data.count) bytes from countries cache file")
            
            let decoder = JSONDecoder()
            let response = try decoder.decode(CountriesResponse.self, from: data)
            
            guard let countries = response.data?.countries else {
                logger.warning("No countries data found in cache")
                return nil
            }
            
            logger.info("Successfully decoded \(countries.count) countries from cache")
            return countries
        } catch {
            logger.error("Error decoding cached countries: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func fetchCountriesFromServer(forceRefresh: Bool = false) {
        logger.info("Fetching countries from server (forceRefresh: \(forceRefresh))")
        RAApiClient.shared.getCountries(forceRefresh: forceRefresh)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingAreas = false
                    switch completion {
                    case .finished:
                        self?.logger.info("Countries fetch completed successfully")
                    case .failure(let error):
                        self?.loadingError = error
                        self?.logger.error("Failed to fetch countries: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    // Check for GraphQL errors
                    if let errors = response.errors, !errors.isEmpty {
                        let errorMessages = errors.map { $0.message }.joined(separator: ", ")
                        self?.loadingError = NSError(domain: "RAGraphQLError", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessages])
                        self?.logger.error("GraphQL errors from countries API: \(errorMessages)")
                        return
                    }
                    
                    guard let countries = response.data?.countries else {
                        self?.loadingError = NSError(domain: "RADataError", code: -2, userInfo: [NSLocalizedDescriptionKey: "No countries data in response"])
                        self?.logger.error("No countries data in response")
                        return
                    }
                    
                    let countryCount = countries.count
                    self?.logger.info("Retrieved \(countryCount) countries from server")
                    
                    // Log total number of areas
                    let totalAreas = countries.reduce(0) { count, country in
                        count + (country.areas?.count ?? 0)
                    }
                    self?.logger.info("Total areas across all countries: \(totalAreas)")
                    
                    self?.countries = countries
                    self?.cacheCountries(response)
                    
                    // Now that we have countries, check if we can find the nearest area
                    if let location = self?.currentLocation {
                        self?.logger.info("Countries loaded and location available - finding nearest area")
                        _ = self?.findNearestArea(to: location)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func cacheCountries(_ response: CountriesResponse) {
        guard let url = getCountriesCacheUrl() else {
            logger.warning("Failed to get cache URL for storing countries")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(response)
            try data.write(to: url)
            logger.info("Successfully cached countries data (\(data.count) bytes)")
        } catch {
            logger.error("Error caching countries: \(error.localizedDescription)")
        }
    }
    
    private func getCountriesCacheUrl() -> URL? {
        let fileManager = FileManager.default
        guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            logger.error("Failed to get cache directory")
            return nil
        }
        
        let cacheFolder = cacheDir.appendingPathComponent("RAData", isDirectory: true)
        
        if !fileManager.fileExists(atPath: cacheFolder.path) {
            do {
                try fileManager.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
                logger.debug("Created cache directory at \(cacheFolder.path)")
            } catch {
                logger.error("Error creating cache directory: \(error.localizedDescription)")
                return nil
            }
        }
        
        return cacheFolder.appendingPathComponent("countries_full.json")
    }
    
    // MARK: - Area Search
    
    func findAreaByName(_ name: String) -> RACountryArea? {
        logger.debug("Searching for area by name: \(name)")
        
        for country in countries {
            if let areas = country.areas {
                if let area = areas.first(where: { $0.name.lowercased() == name.lowercased() }) {
                    logger.info("Found area '\(area.name)' (ID: \(area.id)) in country '\(country.name)'")
                    return area
                }
            }
        }
        logger.warning("Area with name '\(name)' not found")
        return nil
    }
    
    func findAreaById(_ id: String) -> RACountryArea? {
        logger.debug("Searching for area by ID: \(id)")
        
        for country in countries {
            if let areas = country.areas {
                if let area = areas.first(where: { $0.id == id }) {
                    logger.info("Found area '\(area.name)' with ID '\(id)' in country '\(country.name)'")
                    return area
                }
            }
        }
        logger.warning("Area with ID '\(id)' not found")
        return nil
    }
    
    func findNearestArea(to location: CLLocation? = nil) -> RACountryArea? {
        // Use provided location or current location if not specified
        guard let userLocation = location ?? currentLocation else {
            logger.warning("Cannot find nearest area: No location available")
            return nil
        }
        
        logger.info("Finding nearest area to location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
        
        var foundArea: RACountryArea? = nil
        var shortestDistance = Double.greatestFiniteMagnitude
        
        // Create a dictionary to map area IDs to their coordinates
        var areaCoordinates: [String: CLLocationCoordinate2D] = [:]
        
        // Collect venue coordinates from the RA database for known cities
        // Since we don't have coordinates for all areas directly, we'll use some hardcoded major cities' coordinates
        // This is a simplified approach and could be improved with a more comprehensive database
        let knownCityCoordinates: [String: CLLocationCoordinate2D] = [
            "London": CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
            "Berlin": CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
            "New York": CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            "Paris": CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
            "Amsterdam": CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041),
            "Barcelona": CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734),
            "Tokyo": CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            "Los Angeles": CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
            "Miami": CLLocationCoordinate2D(latitude: 25.7617, longitude: -80.1918),
            "Sydney": CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093),
            "Melbourne": CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631),
            "Madrid": CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038),
            "Rome": CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964),
            "Dublin": CLLocationCoordinate2D(latitude: 53.3498, longitude: -6.2603),
            "Vienna": CLLocationCoordinate2D(latitude: 48.2082, longitude: 16.3738),
            "Lisbon": CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393),
            "San Francisco": CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            "Chicago": CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298),
            "Toronto": CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832),
            "Montreal": CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673),
            "Mexico City": CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
            "Seoul": CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            "Hong Kong": CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694),
            "Singapore": CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
            "Stockholm": CLLocationCoordinate2D(latitude: 59.3293, longitude: 18.0686),
            "Milan": CLLocationCoordinate2D(latitude: 45.4642, longitude: 9.1900),
            "Brussels": CLLocationCoordinate2D(latitude: 50.8503, longitude: 4.3517),
            "Copenhagen": CLLocationCoordinate2D(latitude: 55.6761, longitude: 12.5683),
            "Oslo": CLLocationCoordinate2D(latitude: 59.9139, longitude: 10.7522),
            "Helsinki": CLLocationCoordinate2D(latitude: 60.1699, longitude: 24.9384),
            "Athens": CLLocationCoordinate2D(latitude: 37.9838, longitude: 23.7275),
            "Istanbul": CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
            "Dubai": CLLocationCoordinate2D(latitude: 25.2048, longitude: 55.2708),
            "Rio de Janeiro": CLLocationCoordinate2D(latitude: -22.9068, longitude: -43.1729),
            "Sao Paulo": CLLocationCoordinate2D(latitude: -23.5505, longitude: -46.6333)
        ]
        
        // Create a mapping of area names to area objects for lookup
        var areasByName: [String: RACountryArea] = [:]
        
        // Populate the areas by name dictionary
        for country in countries {
            if let areas = country.areas {
                for area in areas {
                    // Skip "All" areas (which represent entire countries)
                    if area.name != "All" {
                        areasByName[area.name] = area
                        
                        // Check if we have coordinates for this city
                        for (cityName, coordinates) in knownCityCoordinates {
                            if area.name.contains(cityName) || cityName.contains(area.name) {
                                areaCoordinates[area.id] = coordinates
                                break
                            }
                        }
                    }
                }
            }
        }
        
        // If we don't have enough coordinates, log a warning
        if areaCoordinates.count < 10 {
            logger.warning("Limited area coordinate data available: only \(areaCoordinates.count) areas with coordinates")
        }
        
        // Calculate distances to each area with known coordinates
        for (areaId, coordinates) in areaCoordinates {
            let areaLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
            let distance = userLocation.distance(from: areaLocation)
            
            if distance < shortestDistance, let area = findAreaById(areaId) {
                shortestDistance = distance
                foundArea = area
            }
        }
        
        if let foundArea = foundArea {
            logger.info("Found nearest area: \(foundArea.name) (ID: \(foundArea.id)) at distance: \(Int(shortestDistance / 1000)) km")
            
            // Update the published property
            nearestArea = foundArea
        } else {
            logger.warning("Could not find nearest area to current location")
        }
        
        return foundArea
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationStatus = manager.authorizationStatus
        
        let statusString = {
            switch manager.authorizationStatus {
            case .notDetermined: return "notDetermined"
            case .restricted: return "restricted"
            case .denied: return "denied"
            case .authorizedAlways: return "authorizedAlways"
            case .authorizedWhenInUse: return "authorizedWhenInUse"
            @unknown default: return "unknown"
            }
        }()
        
        logger.info("Location authorization status changed: \(statusString)")
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied:
            logger.warning("Location permission denied by user")
        case .restricted:
            logger.warning("Location permission restricted")
        case .notDetermined:
            logger.debug("Location permission not determined yet")
        @unknown default:
            logger.warning("Unknown location authorization status")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Only log if location changed significantly or first update
        let shouldLogDetailed = currentLocation == nil || 
                               (currentLocation?.distance(from: location) ?? 0) > 100
        
        if shouldLogDetailed {
            logger.info("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            logger.debug("Location details - Altitude: \(location.altitude)m, Accuracy: \(location.horizontalAccuracy)m")
        }
        
        let isFirstUpdate = currentLocation == nil
        currentLocation = location
        
        // If this is the first location update, notify observers that we now have a location
        if isFirstUpdate {
            logger.info("First location received - ready for nearest area calculation")
            
            // Wait a little bit to make sure the countries are loaded
            if !countries.isEmpty {
                // Update nearestArea property with the result
                _ = findNearestArea()
            } else {
                // If countries aren't loaded yet, delay until they are
                logger.info("Deferring nearest area calculation until countries database is loaded")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("Location manager failed: \(error.localizedDescription)")
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                logger.warning("Location updates denied")
            case .network:
                logger.warning("Network error prevented location update")
            default:
                logger.error("CLError: \(clError.code.rawValue) - \(clError.localizedDescription)")
            }
        }
    }
} 