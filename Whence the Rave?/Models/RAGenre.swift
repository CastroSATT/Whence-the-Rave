import Foundation

/// Represents a music genre from Resident Advisor
struct RAGenre: Identifiable, Codable, Equatable {
    /// Unique identifier for the genre
    let id: String
    
    /// Display name of the genre
    let name: String
    
    /// For Equatable compliance
    static func == (lhs: RAGenre, rhs: RAGenre) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Container for the genres database response
struct GenresResponse: Codable {
    /// Total number of genres
    let total: Int
    
    /// When the genres data was last updated
    let dateUpdated: String
    
    /// List of all available genres
    let genres: [RAGenre]
    
    /// Coding keys for mapping JSON fields
    enum CodingKeys: String, CodingKey {
        case total
        case dateUpdated = "date_updated"
        case genres
    }
} 