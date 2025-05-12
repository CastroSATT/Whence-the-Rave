import Foundation
import CoreLocation

// MARK: - App Domain Models
// These are the domain models used within the application

struct AppEvent: Identifiable, Codable {
    var id: String
    var title: String
    var date: String
    var startTime: String?
    var endTime: String?
    var contentUrl: String
    var flyerFront: String?
    var isTicketed: Bool
    var interestedCount: Int
    var venue: AppVenue?
    var artists: [AppArtist]
    
    var fullEventUrl: String {
        return "https://ra.co\(contentUrl)"
    }
    
    var formattedDate: String {
        // This is a placeholder - we'll implement proper date formatting later
        return date
    }
    
    var popularity: AppEventPopularity {
        if interestedCount >= 500 {
            return .high
        } else if interestedCount >= 100 {
            return .medium
        } else {
            return .low
        }
    }
}

enum AppEventPopularity {
    case low
    case medium
    case high
    
    var color: String {
        switch self {
        case .high:
            return "EventHigh"
        case .medium:
            return "EventMedium"
        case .low:
            return "EventLow"
        }
    }
}

struct AppVenue: Identifiable, Codable {
    var id: String
    var name: String
    var contentUrl: String
    var address: String?
    var area: AppArea?
    var location: AppLocation?
    
    var fullVenueUrl: String {
        return "https://ra.co\(contentUrl)"
    }
}

struct AppLocation: Codable {
    var latitude: Double
    var longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct AppArea: Identifiable, Codable {
    var id: String?
    var name: String
    var country: AppCountry?
}

struct AppCountry: Identifiable, Codable {
    var id: String
    var name: String
}

struct AppArtist: Identifiable, Codable {
    var id: String
    var name: String
    var contentUrl: String
    
    var fullArtistUrl: String {
        return "https://ra.co\(contentUrl)"
    }
}

struct ArtistSocialLinks: Codable {
    let soundcloud: String?
    let instagram: String?
    let twitter: String?
    let bandcamp: String?
    let discogs: String?
    let website: String?
}

extension RAArtist {
    var socialLinks: ArtistSocialLinks? {
        // This will be populated when we fetch the artist details
        return nil
    }
} 