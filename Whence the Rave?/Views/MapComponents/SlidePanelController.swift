import SwiftUI
import os.log

/// Manages the sliding panel animation and offset logic
struct SlidePanelController {
    // MARK: - Properties
    
    /// Width of the panel
    let panelWidth: CGFloat
    
    /// Controls panel visibility
    @Binding var isVisible: Bool
    
    /// Current drag offset
    @Binding var dragOffset: CGFloat
    
    /// Logger for debugging
    private let osLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.whencetheraves", category: "SlidePanelController")
    
    // MARK: - Computed Properties
    
    /// Actual offset of the panel based on current state
    var actualOffset: CGFloat {
        if isVisible {
            // When visible, start from 0 (fully visible)
            return dragOffset
        } else {
            // When hidden, start from -panelWidth (fully hidden)
            return -panelWidth + dragOffset
        }
    }
    
    // Animation parameters for toggling panel visibility
    static let animationResponse: Double = 0.3
    static let animationDamping: Double = 0.75
    
    // Function to toggle panel visibility with animation
    func toggleVisibility() {
        withAnimation(.spring(
            response: Self.animationResponse,
            dampingFraction: Self.animationDamping
        )) {
            isVisible.toggle()
            dragOffset = 0
        }
    }
} 