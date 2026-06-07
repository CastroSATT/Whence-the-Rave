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

enum LegalURLs {
    static let githubRepo = "https://github.com/CastroSATT/Whence-the-Rave"
    static let githubIssues = "https://github.com/CastroSATT/Whence-the-Rave/issues"
    static let privacyPolicy = "https://github.com/CastroSATT/Whence-the-Rave/blob/main/PRIVACY.md"
    static let disclaimer = "https://github.com/CastroSATT/Whence-the-Rave/blob/main/DISCLAIMER.md"
    static let residentAdvisor = "https://ra.co"
    static let residentAdvisorAbout = "https://ra.co/about"
} 