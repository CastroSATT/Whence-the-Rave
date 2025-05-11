import Foundation
import CoreLocation
import SwiftUI

// Make UIKit available for iOS builds
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Shared Extensions

#if canImport(UIKit)
extension UIApplication {
    static func openURL(_ url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
#endif

// Convenience method for creating a conditional binding
extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
} 