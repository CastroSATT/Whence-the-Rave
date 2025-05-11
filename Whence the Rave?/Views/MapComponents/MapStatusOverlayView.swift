import SwiftUI
import os.log

/// View that handles various status overlays for the map screen (loading, empty states)
struct MapStatusOverlayView: View {
    // MARK: - Properties
    
    /// The view model to get status information from
    let viewModel: EventViewModel
    
    /// Action to trigger when requesting to select a location
    let onSelectLocationRequest: () -> Void
    
    /// The logger
    private let logger = AppLogger.shared
    private let osLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.whencetheraves", category: "MapStatusOverlayView")
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.events.isEmpty {
                if viewModel.selectedArea == nil {
                    noLocationSelectedView
                } else if #available(iOS 17.0, *) {
                    noEventsView_iOS17
                } else {
                    noEventsView_Legacy
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("Loading events...")
                .font(.headline)
                .padding()
            
            Text("Finding the best raves around you")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(30)
        .background(Color(UIColor.systemBackground).opacity(0.9))
        .cornerRadius(15)
        .shadow(radius: 10)
    }
    
    // MARK: - No Location Selected View
    
    private var noLocationSelectedView: some View {
        VStack(spacing: 15) {
            Image(systemName: "mappin.circle")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("No Location Selected")
                .font(.headline)
            
            Text("We couldn't automatically detect your area")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button {
                logger.debug("Choose location button tapped from empty state")
                osLogger.debug("🔍 Choose location button tapped from empty state")
                onSelectLocationRequest()
            } label: {
                Text("Choose a Location")
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding(30)
        .background(Color(UIColor.systemBackground).opacity(0.9))
        .cornerRadius(15)
        .shadow(radius: 10)
    }
    
    // MARK: - No Events Views
    
    @available(iOS 17.0, *)
    private var noEventsView_iOS17: some View {
        ContentUnavailableView {
            Label("No Events", systemImage: "map.fill")
        } description: {
            Text("No events found in \(viewModel.selectedArea?.name ?? "selected area"). Try different settings or another location.")
        }
        .background(Color(UIColor.systemBackground).opacity(0.8))
    }
    
    private var noEventsView_Legacy: some View {
        VStack(spacing: 15) {
            Image(systemName: "map.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Events")
                .font(.headline)
            
            Text("No events found in \(viewModel.selectedArea?.name ?? "selected area"). Try different settings or another location.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .background(Color(UIColor.systemBackground).opacity(0.9))
        .cornerRadius(15)
    }
} 