import SwiftUI

struct AnimatedHeaderView: View {
    let showEventList: Bool
    let timePeriodText: String
    
    var body: some View {
        // Check development flag to determine if header should be visible
        if MapConstants.Development.showHeaderTitle {
        VStack(spacing: 0) {
            // Animated title that changes based on showEventList
            ZStack {
                // Event Map title
                Text("Event Map")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(MapConstants.Colors.neonPink)
                    .shadow(color: .black, radius: 2, x: 2, y: 2)
                    .shadow(color: MapConstants.Colors.neonCyan.opacity(0.6), radius: 4, x: 0, y: 0)
                    .italic()
                    .rotationEffect(Angle(degrees: MapConstants.UI.HeaderAnimation.titleRotation))
                    .opacity(showEventList ? 0 : 1)
                    .scaleEffect(showEventList ? MapConstants.UI.HeaderAnimation.titleScale : 1)
                    .offset(x: showEventList ? -MapConstants.UI.HeaderAnimation.titleOffset : 0)
                
                // Event List title
                Text("Event List")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(MapConstants.Colors.neonPink)
                    .shadow(color: .black, radius: 2, x: 2, y: 2)
                    .shadow(color: MapConstants.Colors.neonCyan.opacity(0.6), radius: 4, x: 0, y: 0)
                    .italic()
                    .rotationEffect(Angle(degrees: MapConstants.UI.HeaderAnimation.titleRotation))
                    .opacity(showEventList ? 1 : 0)
                    .scaleEffect(showEventList ? 1 : MapConstants.UI.HeaderAnimation.titleScale)
                    .offset(x: showEventList ? 0 : MapConstants.UI.HeaderAnimation.titleOffset)
            }
            .animation(
                .spring(
                    response: MapConstants.UI.HeaderAnimation.titleSpringResponse,
                    dampingFraction: MapConstants.UI.HeaderAnimation.titleSpringDamping
                ),
                value: showEventList
            )
            .padding(.bottom, 5)
                .allowsHitTesting(false)
                .contentShape(Rectangle().size(width: 0, height: 0))
            
            // Animated subtitle showing time period
            Text(timePeriodText)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(MapConstants.Colors.neonCyan)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
                .shadow(color: MapConstants.Colors.neonPink.opacity(0.6), radius: 3, x: 0, y: 0)
                .italic()
                .rotationEffect(Angle(degrees: MapConstants.UI.HeaderAnimation.subtitleRotation))
                .opacity(showEventList ? 0 : 1)
                .scaleEffect(showEventList ? MapConstants.UI.HeaderAnimation.titleScale : 1)
                .offset(y: showEventList ? MapConstants.UI.HeaderAnimation.subtitleOffset : 0)
                .animation(
                    .spring(
                        response: MapConstants.UI.HeaderAnimation.subtitleSpringResponse,
                        dampingFraction: MapConstants.UI.HeaderAnimation.subtitleSpringDamping
                    )
                    .delay(showEventList ? 0 : MapConstants.UI.HeaderAnimation.subtitleSpringDelay),
                    value: showEventList
                )
                    .allowsHitTesting(false)
        }
        .padding(.top, 2)
            .allowsHitTesting(false)
        } else {
            // Return an empty view when headers are disabled in development
            EmptyView()
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    AnimatedHeaderView(
        showEventList: false,
        timePeriodText: "Events today in London"
    )
    .background(Color.black)
} 