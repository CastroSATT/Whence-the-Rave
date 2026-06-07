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

/// Default implementation that forwards to AppLogger
extension MapLogger {
    func debug(_ message: String) {
        AppLogger.shared.debug(message)
    }
    
    func warning(_ message: String) {
        AppLogger.shared.warning(message)
    }
    
    func error(_ message: String) {
        AppLogger.shared.error(message)
    }
    
    func info(_ message: String) {
        AppLogger.shared.info(message)
    }
} 