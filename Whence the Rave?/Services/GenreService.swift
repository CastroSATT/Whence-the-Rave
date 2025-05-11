import Foundation
import os.log

/// Service for managing music genre data
class GenreService: ObservableObject {
    /// Shared singleton instance
    static let shared = GenreService()
    
    /// All available genres
    @Published private(set) var genres: [RAGenre] = []
    
    /// Whether genres are currently being loaded
    @Published private(set) var isLoadingGenres = false
    
    /// Error encountered during loading, if any
    @Published private(set) var loadingError: Error?
    
    /// Logger for debug information
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.whencetheraves", category: "GenreService")
    
    /// API client for network requests
    private let apiClient = RAApiClient.shared
    
    /// File name for the genres cache
    private let genresCacheFileName = "genres_cache.json"
    
    /// Private initializer for singleton
    private init() {
        logger.info("GenreService initialized")
        loadGenresDatabase()
    }
    
    /// Loads the genres database, optionally forcing a refresh from the API
    func loadGenresDatabase(forceRefresh: Bool = false) {
        logger.info("Loading genres database (forceRefresh: \(forceRefresh))")
        
        // Skip if already loading
        guard !isLoadingGenres else {
            logger.debug("Skipping genre load - already in progress")
            return
        }
        
        isLoadingGenres = true
        loadingError = nil
        
        // Try to load from cache first, unless forced refresh
        if !forceRefresh {
            if loadGenresFromCache() {
                logger.info("Successfully loaded genres from cache")
                isLoadingGenres = false
                return
            }
        }
        
        // Fetch fresh data from API
        fetchGenresFromAPI()
    }
    
    /// Gets a specific genre by ID
    func getGenre(byId id: String) -> RAGenre? {
        return genres.first { $0.id == id }
    }
    
    /// Gets multiple genres by their IDs
    func getGenres(byIds ids: [String]) -> [RAGenre] {
        return genres.filter { genre in ids.contains(genre.id) }
    }
    
    // MARK: - Private Methods
    
    /// Loads genres from the local cache
    private func loadGenresFromCache() -> Bool {
        do {
            guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                logger.error("Failed to get caches directory")
                return false
            }
            
            let raDataFolder = cachesDirectory.appendingPathComponent("RAData", isDirectory: true)
            let cacheFile = raDataFolder.appendingPathComponent(genresCacheFileName)
            
            // Check if file exists
            guard FileManager.default.fileExists(atPath: cacheFile.path) else {
                logger.debug("No genres cache file found")
                return false
            }
            
            // Read cache data
            let cacheData = try Data(contentsOf: cacheFile)
            logger.debug("Read \(cacheData.count) bytes from genres cache file")
            
            // Decode the data
            let genresResponse = try JSONDecoder().decode(GenresResponse.self, from: cacheData)
            logger.info("Successfully decoded \(genresResponse.genres.count) genres from cache (updated: \(genresResponse.dateUpdated))")
            
            // Store genres
            DispatchQueue.main.async {
                self.genres = genresResponse.genres
            }
            
            return true
            
        } catch {
            logger.error("Error loading genres from cache: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Fetches genres from the API
    private func fetchGenresFromAPI() {
        logger.debug("Fetching genres from API")
        
        // GraphQL query based on the Python script
        let query = """
        query GetAllGenres {
          genres {
            id
            name
          }
        }
        """
        
        // Setup payload
        let payload: [String: Any] = [
            "query": query,
            "operationName": "GetAllGenres"
        ]
        
        // Make API request with the same pattern used in Python script
        apiClient.performGraphQLRequest(payload: payload) { [weak self] (data: Data?, error: Error?) in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Error fetching genres: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.loadingError = error
                    self.isLoadingGenres = false
                }
                return
            }
            
            guard let data = data else {
                self.logger.error("No data received from genres API")
                DispatchQueue.main.async {
                    self.loadingError = NSError(domain: "GenreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                    self.isLoadingGenres = false
                }
                return
            }
            
            do {
                // Parse the response data
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                guard let dataDict = json?["data"] as? [String: Any],
                      let genresArray = dataDict["genres"] as? [[String: Any]] else {
                    self.logger.error("Invalid genres response format")
                    DispatchQueue.main.async {
                        self.loadingError = NSError(domain: "GenreService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
                        self.isLoadingGenres = false
                    }
                    return
                }
                
                // Map to genre objects
                let genres = genresArray.compactMap { genreDict -> RAGenre? in
                    guard let id = genreDict["id"] as? String,
                          let name = genreDict["name"] as? String else {
                        return nil
                    }
                    
                    return RAGenre(id: id, name: name)
                }
                
                // Sort genres by name (like in the Python script)
                let sortedGenres = genres.sorted { $0.name < $1.name }
                
                // Create the response structure
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let currentDateString = dateFormatter.string(from: Date())
                
                let genresResponse = GenresResponse(
                    total: sortedGenres.count,
                    dateUpdated: currentDateString,
                    genres: sortedGenres
                )
                
                // Save to cache
                self.saveGenresToCache(genresResponse)
                
                // Update state
                DispatchQueue.main.async {
                    self.genres = sortedGenres
                    self.isLoadingGenres = false
                }
                
                self.logger.info("Successfully loaded \(sortedGenres.count) genres from API")
                
            } catch {
                self.logger.error("Error parsing genres response: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.loadingError = error
                    self.isLoadingGenres = false
                }
            }
        }
    }
    
    /// Saves genres to the local cache
    private func saveGenresToCache(_ genresResponse: GenresResponse) {
        do {
            guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                logger.error("Failed to get caches directory")
                return
            }
            
            let raDataFolder = cachesDirectory.appendingPathComponent("RAData", isDirectory: true)
            
            // Create directory if needed
            if !FileManager.default.fileExists(atPath: raDataFolder.path) {
                try FileManager.default.createDirectory(at: raDataFolder, withIntermediateDirectories: true)
            }
            
            let cacheFile = raDataFolder.appendingPathComponent(genresCacheFileName)
            
            // Encode and save
            let encodedData = try JSONEncoder().encode(genresResponse)
            try encodedData.write(to: cacheFile)
            
            logger.info("Successfully saved \(genresResponse.genres.count) genres to cache")
            
        } catch {
            logger.error("Error saving genres to cache: \(error.localizedDescription)")
        }
    }
} 