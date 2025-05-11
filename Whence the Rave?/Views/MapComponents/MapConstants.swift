import SwiftUI
import MapKit

/// Contains constants and configuration values used across map-related views
enum MapConstants {
    /// Development flags - can be toggled during development
    enum Development {
        /// Controls visibility of title and subtitle in AnimatedHeaderView
        /// Set to false to hide the title and subtitle for development/debugging
        static var showHeaderTitle: Bool = true
    }
    
    /// Map-related constants
    enum Map {
        /// Default map center (London)
        static let defaultCenter = CLLocationCoordinate2D(latitude: 51.5074, longitude: 0.1278)
        
        /// Default zoom level
        static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        
        /// Initial zoom radius in miles
        static let initialZoomMilesRadius: Double = 10.0
        
        /// Map animation duration
        static let animationDuration: Double = 0.3
        
        /// Map animation damping
        static let animationDamping: Double = 0.8
    }
    
    /// UI-related constants
    enum UI {
        /// Distance between controls
        static let standardSpacing: CGFloat = 10
        
        /// Corner radius for rounded elements
        static let cornerRadius: CGFloat = 8
        
        /// Tab dimensions
        static let tabWidth: CGFloat = 40
        static let tabHeight: CGFloat = 80
        
        /// Animation properties
        static let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.8)
        
        /// Standard padding
        static let standardPadding: CGFloat = 8
        static let doublePadding: CGFloat = 16
        
        /// Panel-related constants
        enum Panel {
            /// Multiplier for calculating drag threshold from panel width
            static let dragThresholdMultiplier: CGFloat = 0.3
            
            /// Maximum panel width relative to screen width
            static let maxWidthMultiplier: CGFloat = 0.85
            
            /// Absolute maximum panel width
            static let absoluteMaxWidth: CGFloat = 400
            
            /// Spring animation constants
            static let springResponse: Double = 0.3
            static let springDamping: Double = 0.8
        }
        
        /// Header animation constants
        enum HeaderAnimation {
            static let titleRotation: Double = -6
            static let subtitleRotation: Double = -4
            static let titleOffset: CGFloat = 20
            static let subtitleOffset: CGFloat = 10
            static let titleScale: CGFloat = 0.8
            static let titleSpringResponse: Double = 0.4
            static let titleSpringDamping: Double = 0.8
            static let subtitleSpringResponse: Double = 0.35
            static let subtitleSpringDamping: Double = 0.8
            static let subtitleSpringDelay: Double = 0.1
        }
        
        /// Panel width calculation
        static func panelWidth(for geometry: GeometryProxy) -> CGFloat {
            min(geometry.size.width * 0.85, 400)
        }
        
        /// Drag threshold calculation
        static func dragThreshold(for panelWidth: CGFloat) -> CGFloat {
            panelWidth * 0.3
        }
    }
    
    /// Circle drawing constants
    enum DistanceCircles {
        /// Small circle options
        enum Small {
            static let radiusKm: Double = 1.0
            static let radiusM: Double = 500.0
            static let radiusMi: Double = 1.0
            static let fillColor = Color(red: 144/255, green: 238/255, blue: 144/255, opacity: 0.15)
            static let strokeColor = Color(red: 85/255, green: 187/255, blue: 85/255, opacity: 0.8)
        }
        
        /// Medium circle options
        enum Medium {
            static let radiusKm: Double = 3.0
            static let radiusM: Double = 1000.0
            static let radiusMi: Double = 3.0
            static let fillColor = Color(red: 255/255, green: 236/255, blue: 139/255, opacity: 0.15)
            static let strokeColor = Color(red: 240/255, green: 196/255, blue: 67/255, opacity: 0.8)
        }
        
        /// Large circle options
        enum Large {
            static let radiusKm: Double = 5.0
            static let radiusM: Double = 2000.0
            static let radiusMi: Double = 5.0
            static let fillColor = Color(red: 255/255, green: 182/255, blue: 193/255, opacity: 0.15)
            static let strokeColor = Color(red: 240/255, green: 128/255, blue: 128/255, opacity: 0.8)
        }
        
        /// Line width for all circles
        static let lineWidth: CGFloat = 1.0
    }
    
    /// Color theme
    enum Colors {
        static let panelBackground = Color(UIColor.systemBackground).opacity(0.95)
        static let overlayBackground = Color(UIColor.systemBackground).opacity(0.9)
        static let searchControlsBackground = Color(UIColor.secondarySystemBackground)
        static let listRowBackground = Color.black.opacity(0.8)
        
        // Accent colors based on neon skull image
        static let neonPink = Color(red: 0.9, green: 0.1, blue: 0.8) // Bright magenta
        static let neonCyan = Color(red: 0.1, green: 0.9, blue: 0.9) // Bright cyan/turquoise
        static let neonPurple = Color(red: 0.5, green: 0.2, blue: 0.9) // Purple/indigo
        static let neonBlue = Color(red: 0.2, green: 0.4, blue: 0.9) // Bright blue
        
        // Main accent colors (updated to match the neon scheme)
        static let primary = neonPink
        static let secondary = neonCyan
        static let tertiary = neonBlue
        
        // Gradient for pull tabs
        static let tabGradient = LinearGradient(
            gradient: Gradient(colors: [neonPink, neonPurple, neonCyan]),
            startPoint: .top,
            endPoint: .bottom
        )
        
        // Location button gradient
        static let locationGradient = LinearGradient(
            gradient: Gradient(colors: [neonCyan, neonBlue, neonPink]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
} 