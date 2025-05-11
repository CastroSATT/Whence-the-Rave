import Foundation

struct Constants {
    // API
    static let raBaseUrl = "https://ra.co"
    static let raGraphQLEndpoint = "\(raBaseUrl)/graphql"
    
    // Cache
    static let cacheDirectoryName = "RAData"
    static let countriesCacheFilename = "countries_full.json"
    
    // Default values
    static let defaultLatitude = 51.5074 // London
    static let defaultLongitude = 0.1278
    
    // Map
    static let defaultMapZoom = 0.1
    static let closeMapZoom = 0.01
    
    // Search
    static let searchPageSize = 25
} 