import SwiftUI
import os.log

// Define an enum for distance units
enum DistanceUnit: String, CaseIterable, Identifiable {
    case kilometers = "Kilometers"
    case meters = "Meters"
    case miles = "Miles"
    
    public var id: String { self.rawValue }
    
    func convertMeters(_ meters: Double) -> Double {
        switch self {
        case .kilometers:
            return meters / 1000
        case .meters:
            return meters
        case .miles:
            return meters * 0.000621371
        }
    }
    
    func formatDistance(_ meters: Double) -> String {
        let value = convertMeters(meters)
        switch self {
        case .kilometers:
            return String(format: "%.1f km", value)
        case .meters:
            return String(format: "%.0f m", value)
        case .miles:
            return String(format: "%.1f mi", value)
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
    
    // Empty initializer to prevent compiler warnings
    private init() {
        // Initialize properties directly
        let circlesValue = UserDefaults.standard.object(forKey: "showDistanceCircles") as? Bool ?? true
        let unitString = UserDefaults.standard.string(forKey: "distanceUnit") ?? DistanceUnit.kilometers.rawValue
        let unitValue = DistanceUnit(rawValue: unitString) ?? .kilometers
        let splashValue = UserDefaults.standard.object(forKey: "showSplashOnLaunch") as? Bool ?? false
        
        // Direct assignment
        showDistanceCircles = circlesValue
        distanceUnit = unitValue
        showSplashOnLaunch = splashValue
        
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
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 