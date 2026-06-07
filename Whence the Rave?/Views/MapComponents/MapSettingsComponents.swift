import SwiftUI
import os.log

// Define an enum for distance units
enum DistanceUnit: String, CaseIterable, Identifiable {
    case kilometers = "Kilometers"
    case meters = "Meters"
    case miles = "Miles"
    case walkingTime = "Walking Time"
    
    public var id: String { self.rawValue }
    
    /// Average walking speed: 5 km/h
    static let averageWalkingSpeedMetersPerMinute = 5000.0 / 60.0
    
    func walkingMinutes(fromMeters meters: Double) -> Double {
        meters / Self.averageWalkingSpeedMetersPerMinute
    }
    
    static func formatWalkingTime(minutes: Double) -> String {
        let rounded = Int(minutes.rounded())
        if rounded >= 60 {
            let hours = rounded / 60
            let remaining = rounded % 60
            if remaining == 0 {
                return hours == 1 ? "1 hr" : "\(hours) hr"
            }
            return "\(hours) hr \(remaining) min"
        }
        return "\(rounded) min"
    }
    
    func convertMeters(_ meters: Double) -> Double {
        switch self {
        case .kilometers:
            return meters / 1000
        case .meters:
            return meters
        case .miles:
            return meters * 0.000621371
        case .walkingTime:
            return walkingMinutes(fromMeters: meters)
        }
    }
    
    func formatDistance(_ meters: Double) -> String {
        switch self {
        case .kilometers:
            return String(format: "%.1f km", convertMeters(meters))
        case .meters:
            return String(format: "%.0f m", convertMeters(meters))
        case .miles:
            return String(format: "%.1f mi", convertMeters(meters))
        case .walkingTime:
            return Self.formatWalkingTime(minutes: walkingMinutes(fromMeters: meters))
        }
    }
}

// Class to handle map settings with minimal string interpolation
class MapSettings: ObservableObject {
    static let shared = MapSettings()
    
    // Custom console logging for debugging
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.whencetheraves", category: "MapSettings")
    
    // Simple properties with no observers
    @Published private(set) var showDistanceCircles: Bool
    @Published private(set) var distanceUnit: DistanceUnit
    @Published private(set) var showSplashOnLaunch: Bool
    @Published private(set) var showHeadingIndicator: Bool
    @Published private(set) var genreHapticsEnabled: Bool
    
    // Empty initializer to prevent compiler warnings
    private init() {
        // Initialize properties directly
        let circlesValue = UserDefaults.standard.object(forKey: "showDistanceCircles") as? Bool ?? true
        let unitString = UserDefaults.standard.string(forKey: "distanceUnit") ?? DistanceUnit.kilometers.rawValue
        let unitValue = DistanceUnit(rawValue: unitString) ?? .kilometers
        let splashValue = UserDefaults.standard.object(forKey: "showSplashOnLaunch") as? Bool ?? false
        let headingValue = UserDefaults.standard.object(forKey: "showHeadingIndicator") as? Bool ?? true
        let genreHapticsValue = UserDefaults.standard.object(forKey: "genreHapticsEnabled") as? Bool ?? true
        
        // Direct assignment
        showDistanceCircles = circlesValue
        distanceUnit = unitValue
        showSplashOnLaunch = splashValue
        showHeadingIndicator = headingValue
        genreHapticsEnabled = genreHapticsValue
        
        // Register for notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserDefaultsChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
        
        // Log initialization (no property interpolation)
        logger.debug("MapSettings initialized")
    }
    
    // Setter for distance circles
    func setShowDistanceCircles(_ value: Bool) {
        // Only update if value changed
        if showDistanceCircles != value {
            // Update property first
            showDistanceCircles = value
            
            // Save to UserDefaults
            UserDefaults.standard.set(value, forKey: "showDistanceCircles")
            
            // Log changes (with no property interpolation)
            logCirclesUpdate(value)
            
            // Notify observers
            objectWillChange.send()
        }
    }
    
    // Separate logging method to avoid string interpolation in closures
    private func logCirclesUpdate(_ newValue: Bool) {
        let message = "ShowDistanceCircles updated to: " + (newValue ? "true" : "false")
        logger.debug("\(message)")
    }
    
    // Setter for distance unit
    func setDistanceUnit(_ unit: DistanceUnit) {
        // Only update if value changed
        if distanceUnit != unit {
            // Log the change (without property interpolation)
            logUnitChange(from: distanceUnit, to: unit)
            
            // Update property
            distanceUnit = unit
            
            // Save to UserDefaults
            UserDefaults.standard.set(unit.rawValue, forKey: "distanceUnit")
            
            // Notify observers
            objectWillChange.send()
        }
    }
    
    // Separate logging method to avoid string interpolation in closures
    private func logUnitChange(from oldUnit: DistanceUnit, to newUnit: DistanceUnit) {
        let message = "DistanceUnit changing from: " + oldUnit.rawValue + " to: " + newUnit.rawValue
        logger.debug("\(message)")
    }
    
    // Setter for splash screen setting
    func setShowSplashOnLaunch(_ value: Bool) {
        // Only update if value changed
        if showSplashOnLaunch != value {
            // Update property first
            showSplashOnLaunch = value
            
            // Save to UserDefaults
            UserDefaults.standard.set(value, forKey: "showSplashOnLaunch")
            
            // Log changes
            logSplashUpdate(value)
            
            // Notify observers
            objectWillChange.send()
        }
    }
    
    // Separate logging method for splash setting
    private func logSplashUpdate(_ newValue: Bool) {
        let message = "ShowSplashOnLaunch updated to: " + (newValue ? "true" : "false")
        logger.debug("\(message)")
    }
    
    // Setter for heading indicator
    func setShowHeadingIndicator(_ value: Bool) {
        // Only update if value changed
        if showHeadingIndicator != value {
            // Update property first
            showHeadingIndicator = value
            
            // Save to UserDefaults
            UserDefaults.standard.set(value, forKey: "showHeadingIndicator")
            
            // Log changes
            logHeadingUpdate(value)
            
            // Notify observers
            objectWillChange.send()
        }
    }
    
    // Separate logging method for heading indicator setting
    private func logHeadingUpdate(_ newValue: Bool) {
        let message = "ShowHeadingIndicator updated to: " + (newValue ? "true" : "false")
        logger.debug("\(message)")
    }
    
    func setGenreHapticsEnabled(_ value: Bool) {
        if genreHapticsEnabled != value {
            genreHapticsEnabled = value
            UserDefaults.standard.set(value, forKey: "genreHapticsEnabled")
            logGenreHapticsUpdate(value)
            objectWillChange.send()
        }
    }
    
    private func logGenreHapticsUpdate(_ newValue: Bool) {
        let message = "GenreHapticsEnabled updated to: " + (newValue ? "true" : "false")
        logger.debug("\(message)")
    }
    
    // Handle UserDefaults changes
    @objc private func handleUserDefaultsChange() {
        DispatchQueue.main.async {
            // Check distance unit changes
            if let newUnitString = UserDefaults.standard.string(forKey: "distanceUnit"),
               let newUnit = DistanceUnit(rawValue: newUnitString),
               newUnit != self.distanceUnit {
                
                // Log without property interpolation
                self.logger.debug("UserDefaults distance unit changed to: \(newUnitString)")
                
                // Update property
                self.distanceUnit = newUnit
                self.objectWillChange.send()
            }
            
            // Check circle visibility changes
            if let newCirclesValue = UserDefaults.standard.object(forKey: "showDistanceCircles") as? Bool,
               newCirclesValue != self.showDistanceCircles {
                
                // Log without property interpolation
                let message = newCirclesValue ? "UserDefaults circles enabled" : "UserDefaults circles disabled"
                self.logger.debug("\(message)")
                
                // Update property
                self.showDistanceCircles = newCirclesValue
                self.objectWillChange.send()
            }
            
            // Check splash screen setting changes
            if let newSplashValue = UserDefaults.standard.object(forKey: "showSplashOnLaunch") as? Bool,
               newSplashValue != self.showSplashOnLaunch {
                
                // Log without property interpolation
                let message = newSplashValue ? "UserDefaults splash enabled" : "UserDefaults splash disabled"
                self.logger.debug("\(message)")
                
                // Update property
                self.showSplashOnLaunch = newSplashValue
                self.objectWillChange.send()
            }
            
            // Check heading indicator setting changes
            if let newHeadingValue = UserDefaults.standard.object(forKey: "showHeadingIndicator") as? Bool,
               newHeadingValue != self.showHeadingIndicator {
                
                // Log without property interpolation
                let message = newHeadingValue ? "UserDefaults heading enabled" : "UserDefaults heading disabled"
                self.logger.debug("\(message)")
                
                // Update property
                self.showHeadingIndicator = newHeadingValue
                self.objectWillChange.send()
            }
            
            if let newGenreHapticsValue = UserDefaults.standard.object(forKey: "genreHapticsEnabled") as? Bool,
               newGenreHapticsValue != self.genreHapticsEnabled {
                let message = newGenreHapticsValue ? "UserDefaults genre haptics enabled" : "UserDefaults genre haptics disabled"
                self.logger.debug("\(message)")
                self.genreHapticsEnabled = newGenreHapticsValue
                self.objectWillChange.send()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 