import SwiftUI
import UIKit
import MapKit
import os.log

/// Shared imports for map components.
/// This file helps ensure consistency across map component files.
struct MapImports {
    // Just a placeholder to make this a valid Swift file.
    // The important part is importing all required modules.
}

/// A shared logger protocol that components can use
protocol MapLogger {
    func debug(_ message: String)
    func warning(_ message: String)
    func error(_ message: String)
    func info(_ message: String)
}

/// Default implementation that forwards to AppLogger if available
extension MapLogger {
    func debug(_ message: String) {
        #if DEBUG
        print("DEBUG: \(message)")
        #endif
        
        // Try to use AppLogger if available
        if let appLogger = (NSClassFromString("AppLogger") as? NSObject.Type)?.value(forKey: "shared") as? NSObject {
            _ = appLogger.perform(Selector(("debug:")), with: message)
        }
    }
    
    func warning(_ message: String) {
        #if DEBUG
        print("WARNING: \(message)")
        #endif
        
        // Try to use AppLogger if available
        if let appLogger = (NSClassFromString("AppLogger") as? NSObject.Type)?.value(forKey: "shared") as? NSObject {
            _ = appLogger.perform(Selector(("warning:")), with: message)
        }
    }
    
    func error(_ message: String) {
        #if DEBUG
        print("ERROR: \(message)")
        #endif
        
        // Try to use AppLogger if available
        if let appLogger = (NSClassFromString("AppLogger") as? NSObject.Type)?.value(forKey: "shared") as? NSObject {
            _ = appLogger.perform(Selector(("error:")), with: message)
        }
    }
    
    func info(_ message: String) {
        #if DEBUG
        print("INFO: \(message)")
        #endif
        
        // Try to use AppLogger if available
        if let appLogger = (NSClassFromString("AppLogger") as? NSObject.Type)?.value(forKey: "shared") as? NSObject {
            _ = appLogger.perform(Selector(("info:")), with: message)
        }
    }
} 