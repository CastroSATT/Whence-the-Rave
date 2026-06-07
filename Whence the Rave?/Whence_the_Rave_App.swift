//
//  Whence_the_Rave_App.swift
//  Whence the Rave?
//
//  Created by Jason Mark Allen on 07/05/2025.
//

import SwiftUI
import SwiftData

@main
struct Whence_the_Rave_App: App {
    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    @State private var showSplash: Bool = false
    @ObservedObject private var mapSettings = MapSettings.shared
    
    // Use a lazy property to avoid shared property ambiguity 
    @StateObject private var locationService: LocationService = {
        // Get the shared instance
        let service = LocationService.shared
        return service 
    }()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
            ContentView()
                .environmentObject(locationService)
                    .opacity(showSplash ? 0 : 1)
                
                if showSplash {
                    SplashScreen(isFirstLaunch: $showSplash)
                }
            }
                .onAppear {
                // Show splash screen if it's first launch or enabled in settings
                showSplash = isFirstLaunch || mapSettings.showSplashOnLaunch
                
                // If it was first launch, update the flag
                if isFirstLaunch {
                    isFirstLaunch = false
                }
                
                    // Initialize the location service when the app starts
                    locationService.requestLocationPermission()
                    
                    // Load the countries database
                    locationService.loadCountriesDatabase()
                }
        }
    }
}
