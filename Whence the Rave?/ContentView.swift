//
//  ContentView.swift
//  Whence the Rave?
//
//  Created by Jason Mark Allen on 07/05/2025.
//

import SwiftUI
import CoreLocation
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = EventViewModel()
    @StateObject private var locationService = LocationService.shared
    
    var body: some View {
        NavigationStack {
            EventMapView(viewModel: viewModel)
        }
        .onAppear {
            locationService.requestLocationPermission()
            
            if locationService.locationStatus == .authorizedWhenInUse ||
               locationService.locationStatus == .authorizedAlways {
                locationService.startLocationUpdates()
            }
        }
    }
}

#Preview {
    ContentView()
}
