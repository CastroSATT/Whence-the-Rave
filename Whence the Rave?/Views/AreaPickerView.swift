import SwiftUI
import Combine
import Foundation
import CoreLocation

struct AreaPickerView: View {
    @Binding var selectedArea: RACountryArea?
    @State private var searchText = ""
    @State private var expandedCountries = Set<String>()
    @Environment(\.dismiss) private var dismiss
    
    // Use ObservedObject instead of StateObject since we're getting a shared instance
    @ObservedObject private var locationService = LocationService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                if locationService.isLoadingAreas {
                    ProgressView("Loading areas...")
                } else if let error = locationService.loadingError {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("Error loading areas")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            locationService.loadCountriesDatabase()
                        }
                        .buttonStyle(.bordered)
                        .padding()
                    }
                    .padding()
                } else {
                    List {
                        if !filteredAreas.isEmpty {
                            Section("Search Results") {
                                ForEach(filteredAreas) { area in
                                    AreaRow(area: area, isSelected: selectedArea?.id == area.id)
                                        .onTapGesture {
                                            selectedArea = area
                                            dismiss()
                                        }
                                }
                            }
                        }
                        
                        ForEach(filteredCountries) { country in
                            DisclosureGroup(
                                isExpanded: expandedState(for: country.id),
                                content: {
                                    if let areas = country.areas {
                                        ForEach(areas) { area in
                                            AreaRow(area: area, isSelected: selectedArea?.id == area.id)
                                                .onTapGesture {
                                                    selectedArea = area
                                                    dismiss()
                                                }
                                        }
                                    }
                                },
                                label: {
                                    Text(country.name)
                                        .font(.headline)
                                }
                            )
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search for a city")
                }
            }
            .navigationTitle("Select Area")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func expandedState(for countryId: String) -> Binding<Bool> {
        Binding(
            get: { expandedCountries.contains(countryId) },
            set: { isExpanded in
                if isExpanded {
                    expandedCountries.insert(countryId)
                } else {
                    expandedCountries.remove(countryId)
                }
            }
        )
    }
    
    private var filteredCountries: [RACountry] {
        if searchText.isEmpty {
            return locationService.countries
        } else {
            return locationService.countries.filter { country in
                country.name.lowercased().contains(searchText.lowercased()) ||
                (country.areas?.contains { area in
                    area.name.lowercased().contains(searchText.lowercased())
                } ?? false)
            }
        }
    }
    
    private var filteredAreas: [RACountryArea] {
        if searchText.isEmpty {
            return []
        } else {
            var areas: [RACountryArea] = []
            for country in locationService.countries {
                if let countryAreas = country.areas {
                    let filteredAreas = countryAreas.filter { area in
                        area.name.lowercased().contains(searchText.lowercased())
                    }
                    areas.append(contentsOf: filteredAreas)
                }
            }
            return areas
        }
    }
}

struct AreaRow: View {
    let area: RACountryArea
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text(area.name)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
    }
}

#Preview {
    AreaPickerView(selectedArea: .constant(nil))
}