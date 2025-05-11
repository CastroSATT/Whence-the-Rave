import SwiftUI
import os.log

// Define reference to DistanceUnit enum for settings
enum MapDistanceUnit: String, CaseIterable, Identifiable {
    case kilometers = "Kilometers"
    case meters = "Meters"
    case miles = "Miles"
    
    var id: String { self.rawValue }
}

struct SettingsView: View {
    // Create a logger for debugging
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.whencetheraves", category: "SettingsView")
    
    @AppStorage("refreshOnStartup") private var refreshOnStartup = true
    @State private var showingClearCacheAlert = false
    @State private var isCacheCleared = false
    @State private var isLoadingAreas = false
    @State private var showAreaUpdateResult = false
    @State private var areaUpdateSuccess = false
    @State private var updateMessage = ""
    @ObservedObject private var locationService = LocationService.shared
    
    // Genre database states
    @State private var isLoadingGenres = false
    @State private var showGenreUpdateResult = false
    @State private var genreUpdateSuccess = false
    @State private var genreUpdateMessage = ""
    @ObservedObject private var genreService = GenreService.shared
    
    // Map settings
    @ObservedObject private var mapSettings = MapSettings.shared
    
    // Add EventViewModel as a parameter
    @ObservedObject var viewModel: EventViewModel
    
    // Area picker
    @State private var showingAreaPicker = false
    
    // State to track the selected distance unit from MapSettings
    @State private var selectedDistanceUnit: String
    
    // Initialize with the current MapSettings value
    init(viewModel: EventViewModel) {
        self.viewModel = viewModel
        let initialUnit = MapSettings.shared.distanceUnit.rawValue
        _selectedDistanceUnit = State(initialValue: initialUnit)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
        Form {
                Section {
                    // Neo-punk section header
                    HStack {
                        Text("SEARCH")
                            .font(.system(.headline, design: .monospaced))
                            .fontWeight(.black)
                            .kerning(2)
                            .foregroundColor(.pink)
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.pink, .clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: 1.5)
                            .padding(.leading, 8)
                    }
                    .padding(.vertical, 10)
                    .listRowBackground(Color.black)
                    
                    // Location picker
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.pink)
                            .font(.system(size: 14))
                        
                        Text("LOCATION")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(viewModel.selectedArea?.name ?? "SELECT AREA") {
                            showingAreaPicker = true
                        }
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.green)
                    }
                    
                    // Time Period picker
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.pink)
                            .font(.system(size: 14))
                        
                        Text("TIME PERIOD")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(viewModel.searchDate.rawValue)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.green)
                            .padding(.trailing, 4)
                        
                        Picker("", selection: $viewModel.searchDate) {
                            ForEach(EventViewModel.SearchDateOption.allCases) { option in
                                Text(option.rawValue)
                                    .font(.system(.subheadline, design: .monospaced))
                }
            }
                        .pickerStyle(.menu)
                        .accentColor(.green)
                        .labelsHidden()
                    }
                    
                    // Sort Option picker
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(.pink)
                            .font(.system(size: 14))
                        
                        Text("SORT BY")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(viewModel.sortOption.rawValue)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.green)
                            .padding(.trailing, 4)
                
                        Picker("", selection: $viewModel.sortOption) {
                            ForEach(EventViewModel.SortOption.allCases) { option in
                                Text(option.rawValue)
                                    .font(.system(.subheadline, design: .monospaced))
                    }
                }
                .pickerStyle(.menu)
                        .accentColor(.green)
                        .labelsHidden()
            }
            
                    // Refresh on startup toggle
                HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.pink)
                            .font(.system(size: 14))
                        
                        Text("AUTO REFRESH")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                    Spacer()
                        
                        Toggle("", isOn: $refreshOnStartup)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: .green))
                    }
                }
                .listRowBackground(Color.black.opacity(0.8))
                .textCase(nil)
                
                // Visual section
                Section {
                    // Neo-punk section header
                    HStack {
                        Text("VISUAL")
                            .font(.system(.headline, design: .monospaced))
                            .fontWeight(.black)
                            .kerning(2)
                            .foregroundColor(.pink)
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.pink, .clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: 1.5)
                            .padding(.leading, 8)
                    }
                    .padding(.vertical, 10)
                    .listRowBackground(Color.black)
                    
                    // Show splash screen toggle
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.pink)
                            .font(.system(size: 14))
                        
                        Text("SPLASH SCREEN")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { mapSettings.showSplashOnLaunch },
                            set: { mapSettings.setShowSplashOnLaunch($0) }
                        ))
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                    }
                }
                .listRowBackground(Color.black.opacity(0.8))
                .textCase(nil)
                
                // Map section
                Section {
                    // Neo-punk section header
                    HStack {
                        Text("MAP")
                            .font(.system(.headline, design: .monospaced))
                            .fontWeight(.black)
                            .kerning(2)
                            .foregroundColor(.pink)
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.pink, .clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: 1.5)
                            .padding(.leading, 8)
                    }
                    .padding(.vertical, 10)
                    .listRowBackground(Color.black)
                    
                    // Show distance circles toggle
                    HStack {
                        Image(systemName: "circle.dashed")
                            .foregroundColor(.pink)
                            .font(.system(size: 14))
                        
                        Text("DISTANCE CIRCLES")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { mapSettings.showDistanceCircles },
                            set: { mapSettings.setShowDistanceCircles($0) }
                        ))
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                    }
                    
                    // Distance unit picker
                    HStack {
                        Image(systemName: "ruler")
                            .foregroundColor(.pink)
                            .font(.system(size: 14))
                        
                        Text("DISTANCE UNIT")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(selectedDistanceUnit)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.green)
                            .padding(.trailing, 4)
                        
                        Picker("", selection: $selectedDistanceUnit) {
                            ForEach(MapDistanceUnit.allCases) { unit in
                                Text(unit.rawValue)
                                    .font(.system(.subheadline, design: .monospaced))
                            }
                        }
                        .pickerStyle(.menu)
                        .accentColor(.green)
                        .labelsHidden()
                        .onChange(of: selectedDistanceUnit) { oldValue, newValue in
                            logger.debug("🔄 Distance unit in settings changed from: \(oldValue) to: \(newValue)")
                            
                            // Update UserDefaults
                            UserDefaults.standard.set(newValue, forKey: "distanceUnit")
                            
                            // Use the setter method instead of direct property assignment
                            if let newUnit = DistanceUnit(rawValue: newValue) {
                                logger.debug("✅ Updating MapSettings.shared.distanceUnit to: \(newValue)")
                                mapSettings.setDistanceUnit(newUnit)
                                logger.debug("✅ MapSettings.shared.distanceUnit is now: \(mapSettings.distanceUnit.rawValue)")
                            } else {
                                logger.error("❌ Failed to convert \(newValue) to DistanceUnit")
                            }
                        }
                    }
                }
                .listRowBackground(Color.black.opacity(0.8))
                .textCase(nil)
                
                // Location section
                Section {
                    // Neo-punk section header
                    HStack {
                        Text("LOCATION SERVICES")
                            .font(.system(.headline, design: .monospaced))
                            .fontWeight(.black)
                            .kerning(2)
                            .foregroundColor(.pink)
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.pink, .clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: 1.5)
                            .padding(.leading, 8)
                    }
                    .padding(.vertical, 10)
                    .listRowBackground(Color.black)
                
                HStack {
                        Image(systemName: "location.viewfinder")
                            .foregroundColor(.pink)
                            .font(.system(size: 14))
                        
                        Text("LOCATION STATUS")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                    Spacer()
                        
                        Text(locationStatusString)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.pink)
                                .font(.system(size: 14))
                            
                            Text("OPEN LOCATION SETTINGS")
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .listRowBackground(Color.black.opacity(0.8))
                .textCase(nil)
                
                // Data management section
                Section {
                    // Neo-punk section header
                    HStack {
                        Text("DATA")
                            .font(.system(.headline, design: .monospaced))
                            .fontWeight(.black)
                            .kerning(2)
                            .foregroundColor(.pink)
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.pink, .clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: 1.5)
                            .padding(.leading, 8)
                    }
                    .padding(.vertical, 10)
                    .listRowBackground(Color.black)
                    
                    Button(action: {
                        showingClearCacheAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.pink)
                                .font(.system(size: 14))
                            
                            Text("CLEAR CACHE")
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.pink)
                            .font(.system(size: 14))
                        
                        Text("AREAS DATABASE")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if isLoadingAreas {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.green)
                        } else {
                            Text(locationService.countries.isEmpty ? "NOT LOADED" : "\(locationService.countries.count) AREAS")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.green)
                    }
                    
                    Button(action: updateAreasDatabase) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundColor(.pink)
                                .font(.system(size: 16))
                        }
                        .disabled(isLoadingAreas)
                    }
                    
                    // Genre database status
                    HStack {
                        Image(systemName: "music.note.list")
                                .foregroundColor(.pink)
                                .font(.system(size: 14))
                            
                        Text("GENRES DATABASE")
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        
                        Spacer()
                            
                        if isLoadingGenres {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(.green)
                        } else {
                            Text(genreService.genres.isEmpty ? "NOT LOADED" : "\(genreService.genres.count) GENRES")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.green)
                        }
                        
                        Button(action: updateGenresDatabase) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundColor(.pink)
                                .font(.system(size: 16))
                }
                        .disabled(isLoadingGenres)
                    }
            }
                .listRowBackground(Color.black.opacity(0.8))
                .textCase(nil)
                
                // About section
                Section {
                    // Neo-punk section header
                    HStack {
                        Text("ABOUT")
                            .font(.system(.headline, design: .monospaced))
                            .fontWeight(.black)
                            .kerning(2)
                            .foregroundColor(.pink)
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.pink, .clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: 1.5)
                            .padding(.leading, 8)
                    }
                    .padding(.vertical, 10)
                    .listRowBackground(Color.black)
                    
                HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.pink)
                            .font(.system(size: 14))
                        
                        Text("APP VERSION")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                    Spacer()
                        
                    Text(appVersion)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.green)
                }
                
                    Button {
                    if let url = URL(string: "https://github.com/whenceartthouraves") {
                        UIApplication.shared.open(url)
                    }
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .foregroundColor(.pink)
                                .font(.system(size: 14))
                            
                            Text("VIEW SOURCE")
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                }
                
                    Button {
                    if let url = URL(string: "https://ra.co/about") {
                        UIApplication.shared.open(url)
                    }
                    } label: {
                        HStack {
                            Image(systemName: "music.note")
                                .foregroundColor(.pink)
                                .font(.system(size: 14))
                            
                            Text("ABOUT RESIDENT ADVISOR")
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
                }
                .listRowBackground(Color.black.opacity(0.8))
                .textCase(nil)
            }
            .scrollContentBackground(.hidden)
        }
        .accentColor(.green)
        .navigationTitle("SETTINGS")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("This will clear all cached data including saved areas and event listings. The app will need to download this data again.")
        }
        .alert("Cache Cleared", isPresented: $isCacheCleared) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("All cached data has been cleared successfully.")
        }
        .alert(areaUpdateSuccess ? "Database Updated" : "Update Failed", isPresented: $showAreaUpdateResult) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(updateMessage)
        }
        .alert(genreUpdateSuccess ? "Genres Updated" : "Genre Update Failed", isPresented: $showGenreUpdateResult) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(genreUpdateMessage)
        }
        .sheet(isPresented: $showingAreaPicker) {
            AreaPickerView(selectedArea: $viewModel.selectedArea)
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            isLoadingAreas = locationService.isLoadingAreas
            isLoadingGenres = genreService.isLoadingGenres
            
            // Make sure our selection is in sync with MapSettings
            selectedDistanceUnit = mapSettings.distanceUnit.rawValue
            logger.debug("📱 SettingsView appeared. Current distance unit: \(selectedDistanceUnit)")
            logger.debug("📱 MapSettings.shared.distanceUnit is now: \(mapSettings.distanceUnit.rawValue)")
        }
        // Monitor loading state for areas
        .onChange(of: locationService.isLoadingAreas) { _, newValue in
            isLoadingAreas = newValue
            
            // If loading just completed, show result
            if !newValue && isLoadingAreas {
                showUpdateResult()
            }
        }
        // Monitor loading state for genres
        .onChange(of: genreService.isLoadingGenres) { _, newValue in
            isLoadingGenres = newValue
            
            // If loading just completed, show result
            if !newValue && isLoadingGenres {
                displayGenreUpdateResult()
            }
        }
    }
    
    private var locationStatusString: String {
        switch LocationService.shared.locationStatus {
        case .notDetermined:
            return "NOT DETERMINED"
        case .restricted:
            return "RESTRICTED"
        case .denied:
            return "DENIED"
        case .authorizedAlways:
            return "ALWAYS"
        case .authorizedWhenInUse:
            return "WHEN IN USE"
        case .authorized:
            return "AUTHORIZED"
        @unknown default:
            return "UNKNOWN"
        }
    }
    
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return "Unknown"
    }
    
    private func clearCache() {
        // Clear the FileManager cache directory
        let fileManager = FileManager.default
        if let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let raDataFolder = cacheDirectory.appendingPathComponent("RAData", isDirectory: true)
            
            do {
                if fileManager.fileExists(atPath: raDataFolder.path) {
                    try fileManager.removeItem(at: raDataFolder)
                }
                isCacheCleared = true
            } catch {
                print("Error clearing cache: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateAreasDatabase() {
        isLoadingAreas = true
        
        // Reset any previous errors
        updateMessage = ""
        showAreaUpdateResult = false
        
        // Start the update process - force refresh from API
        locationService.loadCountriesDatabase(forceRefresh: true)
        
        // Set up a timer to check the result after a few seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if let error = locationService.loadingError {
                // Update failed
                areaUpdateSuccess = false
                updateMessage = "Error updating database: \(error.localizedDescription)"
            } else if locationService.countries.isEmpty {
                // No data returned but no error
                areaUpdateSuccess = false
                updateMessage = "No areas were loaded. Please check your internet connection and try again."
            } else {
                // Success!
                areaUpdateSuccess = true
                updateMessage = "Successfully loaded \(locationService.countries.count) countries and regions."
            }
            
            showAreaUpdateResult = true
            isLoadingAreas = false
        }
    }
    
    private func showUpdateResult() {
        if let error = locationService.loadingError {
            // Update failed
            areaUpdateSuccess = false
            updateMessage = "Error updating database: \(error.localizedDescription)"
            showAreaUpdateResult = true
        } else if !locationService.countries.isEmpty {
            // Success!
            areaUpdateSuccess = true
            updateMessage = "Successfully loaded \(locationService.countries.count) countries and regions."
            showAreaUpdateResult = true
        }
    }
    
    private func updateGenresDatabase() {
        isLoadingGenres = true
        
        // Reset any previous errors
        genreUpdateMessage = ""
        showGenreUpdateResult = false
        
        // Start the update process - force refresh from API
        genreService.loadGenresDatabase(forceRefresh: true)
        
        // Set up a timer to check the result after a few seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if let error = genreService.loadingError {
                // Update failed
                genreUpdateSuccess = false
                genreUpdateMessage = "Error updating genres: \(error.localizedDescription)"
            } else if genreService.genres.isEmpty {
                // No data returned but no error
                genreUpdateSuccess = false
                genreUpdateMessage = "No genres were loaded. Please check your internet connection and try again."
            } else {
                // Success!
                genreUpdateSuccess = true
                genreUpdateMessage = "Successfully loaded \(genreService.genres.count) music genres."
            }
            
            showGenreUpdateResult = true
            isLoadingGenres = false
        }
    }
    
    private func displayGenreUpdateResult() {
        if let error = genreService.loadingError {
            // Update failed
            genreUpdateSuccess = false
            genreUpdateMessage = "Error updating genres: \(error.localizedDescription)"
            showGenreUpdateResult = true
        } else if !genreService.genres.isEmpty {
            // Success!
            genreUpdateSuccess = true
            genreUpdateMessage = "Successfully loaded \(genreService.genres.count) music genres."
            showGenreUpdateResult = true
        }
    }
} 