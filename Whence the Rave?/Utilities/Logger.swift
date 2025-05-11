import Foundation
import os.log

/// A simple logger utility for consistent debug logging throughout the app
class AppLogger {
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }
    
    static let shared = AppLogger()
    
    // Use OSLog for better performance in production
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app.whence-the-rave", category: "WhenceTheRave")
    
    // Log to console with optional file, function, line info
    func log(_ message: String, level: LogLevel = .debug, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
        let fileURL = URL(fileURLWithPath: fileName)
        let className = fileURL.lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        
        let logMessage = "[\(level.rawValue)] [\(className)] \(functionName) [Line \(lineNumber)]: \(message)"
        
        // Print to console
        print(logMessage)
        
        // Also use OSLog with appropriate log level
        switch level {
        case .debug:
            logger.debug("\(logMessage)")
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        }
    }
    
    // Convenience methods
    func debug(_ message: String, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
        log(message, level: .debug, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
    }
    
    func info(_ message: String, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
        log(message, level: .info, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
    }
    
    func warning(_ message: String, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
        log(message, level: .warning, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
    }
    
    func error(_ message: String, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
        log(message, level: .error, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
    }
} 