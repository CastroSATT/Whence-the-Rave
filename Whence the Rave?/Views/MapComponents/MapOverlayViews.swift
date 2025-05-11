import SwiftUI

/// Contains the various overlay views displayed on the map (loading, empty states)
struct MapOverlayViews: View {
    let events: [RAEvent]
    let isLoading: Bool
    let selectedArea: RACountryArea?
    var onShowSettings: () -> Void
    
    var body: some View {
        ZStack {
            if isLoading {
                loadingOverlay
            } else if events.isEmpty {
                if selectedArea == nil {
                    noLocationSelectedOverlay
                } else if #available(iOS 17.0, *) {
                    emptyEventsOverlay17
                } else {
                    emptyEventsOverlayLegacy
                }
            }
        }
    }
    
    // Loading overlay
    private var loadingOverlay: some View {
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
    
    // No location selected overlay
    private var noLocationSelectedOverlay: some View {
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
                AppLogger.shared.debug("Choose location button tapped from empty state")
                onShowSettings()
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
    
    // iOS 17+ empty events overlay
    @available(iOS 17.0, *)
    private var emptyEventsOverlay17: some View {
        ContentUnavailableView {
            Label("No Events", systemImage: "map.fill")
        } description: {
            Text("No events found in \(selectedArea?.name ?? "selected area"). Try different settings or another location.")
        }
        .background(Color(UIColor.systemBackground).opacity(0.8))
    }
    
    // iOS 16 and earlier empty events overlay
    private var emptyEventsOverlayLegacy: some View {
        VStack(spacing: 15) {
            Image(systemName: "map.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Events")
                .font(.headline)
            
            Text("No events found in \(selectedArea?.name ?? "selected area"). Try different settings or another location.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .background(Color(UIColor.systemBackground).opacity(0.9))
        .cornerRadius(15)
    }
} 