import Foundation
import Combine
import CoreLocation

// MARK: - API Response Models
struct RACountry: Codable, Identifiable {
    var id: String
    var name: String
    var areas: [RACountryArea]?
}

struct RACountryArea: Codable, Identifiable {
    var id: String
    var name: String
    var urlName: String?
    var isCountry: Bool?
    
    // Add any custom functionality or computed properties here
}

struct RAEvent: Codable, Identifiable {
    var id: String
    var title: String
    var date: String
    var startTime: String?
    var endTime: String?
    var contentUrl: String
    var flyerFront: String?
    var isTicketed: Bool
    var interestedCount: Int
    var isSaved: Bool?
    var isInterested: Bool?
    var queueItEnabled: Bool?
    var newEventForm: Bool?
    var venue: RAVenue?
    var promoters: [RAPromoter]?
    var artists: [RAArtist]
    var tickets: [RATicket]?
    var images: [RAImage]?
    var pick: RAPick?
}

struct RAImage: Codable, Identifiable {
    var id: String
    var filename: String
    var alt: String?
    var type: String
    var crop: String?
}

struct RAPick: Codable, Identifiable {
    var id: String
    var blurb: String?
}

struct RAPromoter: Codable, Identifiable {
    var id: String
}

struct RATicket: Codable {
    var validType: String
    var onSaleFrom: String?
    var onSaleUntil: String?
}

struct RAVenue: Codable, Identifiable {
    var id: String
    var name: String
    var contentUrl: String?
    var address: String?
    var area: RAArea?
    var location: RALocation?
    var live: Bool?
}

struct RALocation: Codable {
    var latitude: Double
    var longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct RAArea: Codable {
    var name: String
}

struct RAArtist: Codable, Identifiable {
    var id: String
    var name: String
    var contentUrl: String?
}

struct EventsResponse: Codable {
    let data: EventsResponseData?
    let errors: [GraphQLError]?
}

struct GraphQLError: Codable {
    let message: String
    let locations: [GraphQLErrorLocation]?
    let path: [String]?
    let extensions: [String: String]?
}

struct GraphQLErrorLocation: Codable {
    let line: Int
    let column: Int
}

struct EventsResponseData: Codable {
    let eventListingsWithBumps: EventListingsWithBumps?
}

struct EventListingsWithBumps: Codable {
    let eventListings: EventListings
    let bumps: EventBumps?
}

struct EventBumps: Codable {
    let bumpDecision: [BumpDecision]?
}

struct BumpDecision: Codable, Identifiable {
    let id: String
    let date: String
    let eventId: String
    let clickUrl: String?
    let impressionUrl: String?
    let event: RAEvent
}

struct EventListings: Codable {
    let data: [EventListing]
    let totalResults: Int
    let filterOptions: FilterOptions?
}

struct FilterOptions: Codable {
    let genre: [FilterOption]?
    let eventType: [FilterTypeOption]?
    let location: [LocationFilterOption]?
}

struct FilterOption: Codable {
    let label: String
    let value: String
    let count: Int
}

struct FilterTypeOption: Codable {
    // Value can be either String or Int from the API
    let value: Any
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case value
        case count
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        count = try container.decode(Int.self, forKey: .count)
        
        // Try to decode as String first, then Int if that fails
        if let stringValue = try? container.decode(String.self, forKey: .value) {
            value = stringValue
        } else if let intValue = try? container.decode(Int.self, forKey: .value) {
            value = intValue
        } else {
            throw DecodingError.dataCorruptedError(forKey: .value, in: container, debugDescription: "Expected String or Int")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(count, forKey: .count)
        
        if let stringValue = value as? String {
            try container.encode(stringValue, forKey: .value)
        } else if let intValue = value as? Int {
            try container.encode(intValue, forKey: .value)
        }
    }
}

struct LocationFilterOption: Codable {
    let value: LocationFilterValue
    let count: Int
}

struct LocationFilterValue: Codable {
    let from: Double?
    let to: Double?
}

struct EventListing: Codable {
    let id: String
    let listingDate: String
    let event: RAEvent
}

struct CountriesResponse: Codable {
    let data: CountriesData?
    let errors: [GraphQLError]?
}

struct CountriesData: Codable {
    let countries: [RACountry]?
}

class RAApiClient {
    static let shared = RAApiClient()
    
    // Use the same GraphQL endpoint as the Python implementation
    private let baseURL = "https://ra.co/graphql"
    private let logger = AppLogger.shared
    
    private init() {
        logger.info("RAApiClient initialized")
    }
    
    // Diagnostic method to check the GraphQL schema
    func diagnoseGraphQLSchema() -> AnyPublisher<Data, Error> {
        logger.debug("Attempting to query GraphQL introspection")
        
        // This is a standard GraphQL introspection query to get schema details
        let query = """
        {
          __schema {
            queryType {
              name
              fields {
                name
                description
              }
            }
          }
        }
        """
        
        // Set up the request directly, following Python approach
        guard let url = URL(string: baseURL) else {
            logger.error("Invalid URL: \(baseURL)")
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Same headers as other requests
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.addValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.addValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.addValue("https://ra.co", forHTTPHeaderField: "Origin")
        request.addValue("https://ra.co/events/uk/london", forHTTPHeaderField: "Referer")
        
        let payload: [String: Any] = ["query": query]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            logger.error("Failed to serialize request body: \(error.localizedDescription)")
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        // First visit ra.co to get cookies
        let session = URLSession.shared
        
        return session.dataTaskPublisher(for: URL(string: "https://ra.co")!)
            .mapError { $0 as Error }
            .flatMap { _ in
                // Then make the actual API request
                return session.dataTaskPublisher(for: request)
                    .mapError { $0 as Error }
            }
            .map(\.data)
            .eraseToAnyPublisher()
    }
    
    // Get a list of events for a specific area - direct HTTP approach
    func getEventsByArea(areaId: String, dateFrom: String, dateTo: String, sort: String = "LATEST", page: Int = 1, pageSize: Int = 25) -> AnyPublisher<EventsResponse, Error> {
        logger.debug("Getting events for area \(areaId), from \(dateFrom) to \(dateTo), sort: \(sort)")
        
        guard let url = URL(string: baseURL) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        // Use the exact query from Python implementation
        let query = """
        query GET_EVENT_LISTINGS_WITH_BUMPS($filters: FilterInputDtoInput, $filterOptions: FilterOptionsInputDtoInput, $page: Int, $pageSize: Int, $sort: SortInputDtoInput, $areaId: ID) {
          eventListingsWithBumps(
            filters: $filters
            filterOptions: $filterOptions
            pageSize: $pageSize
            page: $page
            sort: $sort
            areaId: $areaId
          ) {
            eventListings {
              data {
                id
                listingDate
                event {
                  id
                  date
                  startTime
                  endTime
                  title
                  contentUrl
                  flyerFront
                  isTicketed
                  interestedCount
                  isSaved
                  isInterested
                  queueItEnabled
                  newEventForm
                  images {
                    id
                    filename
                    alt
                    type
                    crop
                  }
                  pick {
                    id
                    blurb
                  }
                  venue {
                    id
                    name
                    contentUrl
                    live
                    area {
                      name
                    }
                    address
                    location {
                      latitude
                      longitude
                    }
                  }
                  promoters {
                    id
                  }
                  artists {
                    id
                    name
                    contentUrl
                  }
                  tickets(queryType: AVAILABLE) {
                    validType
                    onSaleFrom
                    onSaleUntil
                  }
                }
              }
              filterOptions {
                genre {
                  label
                  value
                  count
                }
                eventType {
                  value
                  count
                }
                location {
                  value {
                    from
                    to
                  }
                  count
                }
              }
              totalResults
            }
            bumps {
              bumpDecision {
                id
                date
                eventId
                clickUrl
                impressionUrl
                event {
                  id
                  date
                  startTime
                  endTime
                  title
                  contentUrl
                  flyerFront
                  isTicketed
                  interestedCount
                  isSaved
                  isInterested
                  queueItEnabled
                  newEventForm
                  images {
                    id
                    filename
                    alt
                    type
                    crop
                  }
                  pick {
                    id
                    blurb
                  }
                  venue {
            id
            name
                    contentUrl
                    live
                    area {
                      name
                    }
                    address
                    location {
                      latitude
                      longitude
                    }
                  }
                  promoters {
                    id
                  }
                  artists {
              id
              name
                  }
                  tickets(queryType: AVAILABLE) {
                    validType
                    onSaleFrom
                    onSaleUntil
                  }
                }
              }
            }
          }
        }
        """
        
        // Check if we're looking for a specific day
        let isSingleDay = dateFrom == dateTo
        
        // Create variables exactly like Python
        var variableDict: [String: Any] = [
            "areaId": Int(areaId) ?? 0,
            "filterOptions": [
                "genre": true,
                "eventType": true
            ],
            "filters": [
                "areas": ["eq": Int(areaId) ?? 0]
            ],
            "page": page,
            "pageSize": pageSize
        ]
        
        // Add date filtering based on whether it's a single day or range
        var filtersDict = variableDict["filters"] as? [String: Any] ?? [:]
        
        if isSingleDay {
            logger.debug("Using single day date filter: \(dateFrom)")
            // For a single day, we want events on that specific day
            // RA uses this format for filtering by a single date
            filtersDict["listingDate"] = [
                "gte": dateFrom,
                "lte": dateFrom
            ]
            // Also add a more reliable filter for the specific day
            filtersDict["startTime"] = [
                "gte": dateFrom + "T00:00:00.000",
                "lte": dateFrom + "T23:59:59.999"
            ]
        } else {
            logger.debug("Using date range filter: \(dateFrom) to \(dateTo)")
            filtersDict["listingDate"] = [
                "gte": dateFrom,
                "lte": dateTo
            ]
        }
        
        // Update the filters in the variables dictionary
        variableDict["filters"] = filtersDict
        
        // Add sort using the format from the Python implementation
        variableDict["sort"] = getSortDictionary(sort: sort)
        
        // Verify our variable structure matches Python's implementation
        logger.debug("areaId type: \(type(of: variableDict["areaId"]!))")
        if let filtersDict = variableDict["filters"] as? [String: Any],
           let areas = filtersDict["areas"] as? [String: Any],
           let eqValue = areas["eq"] {
            logger.debug("areas.eq type: \(type(of: eqValue))")
        }
        
        let payload: [String: Any] = [
            "query": query,
            "variables": variableDict,
            "operationName": "GET_EVENT_LISTINGS_WITH_BUMPS"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set headers exactly like Python implementation
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.addValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.addValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.addValue("https://ra.co", forHTTPHeaderField: "Origin")
        request.addValue("https://ra.co/events/uk/london", forHTTPHeaderField: "Referer")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            // Debug output
            if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
                logger.debug("Request payload: \(jsonString)")
            }
        } catch {
            logger.error("Failed to serialize request body: \(error.localizedDescription)")
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        // Create a session and first visit the main site - exactly like Python
        let session = URLSession.shared
        
        return session.dataTaskPublisher(for: URL(string: "https://ra.co")!)
            .mapError { $0 as Error }
            .flatMap { _ -> AnyPublisher<(data: Data, response: URLResponse), Error> in
                self.logger.debug("Successfully visited main site, now making API request")
                return session.dataTaskPublisher(for: request)
                    .mapError { $0 as Error }
                    .eraseToAnyPublisher()
            }
            .tryMap { output -> Data in
                // Log the response for debugging
                let httpResponse = output.response as? HTTPURLResponse
                self.logger.debug("API Response Status: \(httpResponse?.statusCode ?? 0)")
                
                if let httpResponse = httpResponse, !(200...299).contains(httpResponse.statusCode) {
                    self.logger.error("HTTP Error: \(httpResponse.statusCode)")
                    throw URLError(.badServerResponse)
                }
                
                // Log some of the response data for debugging
                if let responseStr = String(data: output.data, encoding: .utf8) {
                    let previewLength = min(1000, responseStr.count)
                    self.logger.debug("Response preview: \(responseStr.prefix(previewLength))")
                    
                    // Save the full response for debugging
                    self.saveDebugData(output.data, filename: "debug_response.json")
                }
                
                return output.data
            }
            .decode(type: EventsResponse.self, decoder: JSONDecoder())
            .catch { error -> AnyPublisher<EventsResponse, Error> in
                // Add detailed logging for decoding errors
                if let decodingError = error as? DecodingError {
                    self.logger.error("JSON Decoding Error: \(decodingError)")
                    
                    switch decodingError {
                    case .dataCorrupted(let context):
                        self.logger.error("Data corrupted: \(context.debugDescription)")
                        self.logger.error("Coding path: \(context.codingPath)")
                    case .keyNotFound(let key, let context):
                        self.logger.error("Key not found: \(key.stringValue) at path: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        self.logger.error("Value of type \(type) not found at path: \(context.codingPath)")
                        self.logger.error("Debug description: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        self.logger.error("Type mismatch: expected \(type) at path: \(context.codingPath)")
                    @unknown default:
                        self.logger.error("Unknown decoding error")
                    }
                } else {
                    self.logger.error("Non-decoding error: \(error)")
                }
                
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // Helper function to get the sort dictionary based on sort parameter
    private func getSortDictionary(sort: String) -> [String: [String: String]] {
        logger.debug("Creating sort dictionary for: \(sort)")
        
        switch sort {
        case "LATEST":
            logger.debug("Using LATEST sort order (ascending listingDate)")
            return [
                "listingDate": ["order": "ASCENDING"],
                "score": ["order": "DESCENDING"],
                "titleKeyword": ["order": "ASCENDING"]
            ]
        case "POPULAR":
            logger.debug("Using POPULAR sort order (descending score)")
            return [
                "score": ["order": "DESCENDING"],
                "listingDate": ["order": "ASCENDING"],
                "titleKeyword": ["order": "ASCENDING"]
            ]
        case "ALPHABETICAL":
            logger.debug("Using ALPHABETICAL sort order (ascending titleKeyword)")
            return [
                "titleKeyword": ["order": "ASCENDING"],
                "score": ["order": "DESCENDING"],
                "listingDate": ["order": "ASCENDING"]
            ]
        default:
            logger.debug("Unknown sort option '\(sort)', defaulting to LATEST")
            return [
                "listingDate": ["order": "ASCENDING"],
                "score": ["order": "DESCENDING"],
                "titleKeyword": ["order": "ASCENDING"]
            ]
        }
    }
    
    // Get all events for an area by handling pagination - matches Python's get_all_events_for_area function
    func getAllEventsByArea(areaId: String, dateFrom: String, dateTo: String, sort: String = "LATEST", pageSize: Int = 100) -> AnyPublisher<EventsResponse, Error> {
        logger.info("Fetching all events for area \(areaId), from \(dateFrom) to \(dateTo)")
        
        // Create a subject that will emit our aggregated events
        let subject = PassthroughSubject<EventsResponse, Error>()
        
        // Track our state
        var allEvents: [EventListing] = []
        var page = 1
        var hasMorePages = true
        var totalResults: Int? = nil
        
        // Function to fetch a single page
        func fetchPage() {
            logger.debug("Fetching page \(page) with pageSize \(pageSize)")
            
            self.getEventsByArea(areaId: areaId, dateFrom: dateFrom, dateTo: dateTo, sort: sort, page: page, pageSize: pageSize)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            // If we're done with all pages, emit the aggregated result
                            if !hasMorePages {
                                self.logger.info("Completed fetching all pages, total events: \(allEvents.count)")
                                
                                // Create a final aggregate response with all events
                                var finalResponse = EventsResponse(data: nil, errors: nil)
                                
                                // Only create data structure if we have events
                                if !allEvents.isEmpty {
                                    let eventListings = EventListings(data: allEvents, totalResults: totalResults ?? allEvents.count, filterOptions: nil)
                                    let eventListingsWithBumps = EventListingsWithBumps(eventListings: eventListings, bumps: nil)
                                    let responseData = EventsResponseData(eventListingsWithBumps: eventListingsWithBumps)
                                    finalResponse = EventsResponse(data: responseData, errors: nil)
                                }
                                
                                subject.send(finalResponse)
                                subject.send(completion: .finished)
                            }
                        case .failure(let error):
                            self.logger.error("Error fetching page \(page): \(error)")
                            
                            // Log more detailed error info
                            if let decodingError = error as? DecodingError {
                                self.logger.error("JSON decoding error in pagination: \(decodingError)")
                                
                                // If we have events already but a later page fails, we can still return what we have
                                if !allEvents.isEmpty {
                                    self.logger.info("Returning \(allEvents.count) events that were fetched before the error")
                                    
                                    let eventListings = EventListings(data: allEvents, totalResults: totalResults ?? allEvents.count, filterOptions: nil)
                                    let eventListingsWithBumps = EventListingsWithBumps(eventListings: eventListings, bumps: nil)
                                    let responseData = EventsResponseData(eventListingsWithBumps: eventListingsWithBumps)
                                    let partialResponse = EventsResponse(
                                        data: responseData,
                                        errors: [GraphQLError(message: "Pagination error: \(error.localizedDescription)", locations: nil, path: nil, extensions: nil)]
                                    )
                                    
                                    subject.send(partialResponse)
                                    subject.send(completion: .finished)
                                    return
                                }
                            }
                            
                            subject.send(completion: .failure(error))
                        }
                    },
                    receiveValue: { response in
                        // Check for GraphQL errors first
                        if let errors = response.errors, !errors.isEmpty {
                            let errorMessages = errors.map { $0.message }.joined(separator: ", ")
                            self.logger.error("GraphQL errors received: \(errorMessages)")
                            
                            // Still continue if we have some data
                            if response.data == nil {
                                hasMorePages = false
                                return
                            }
                        }
                        
                        // Check that we have valid data in the response
                        guard let eventListingsWithBumps = response.data?.eventListingsWithBumps else {
                            self.logger.error("No eventListingsWithBumps data in the response")
                            hasMorePages = false
                            return
                        }
                        
                        // Get events from this page
                        let eventsOnPage = eventListingsWithBumps.eventListings.data
                        
                        // Verify the events are within the requested date range
                        let verifiedEvents = self.verifyEventsInDateRange(events: eventsOnPage, dateFrom: dateFrom, dateTo: dateTo)
                        if verifiedEvents.count < eventsOnPage.count {
                            self.logger.warning("Filtered out \(eventsOnPage.count - verifiedEvents.count) events outside requested date range")
                        }
                        
                        // Store total results if this is the first page (like Python does)
                        if page == 1 {
                            totalResults = eventListingsWithBumps.eventListings.totalResults
                            self.logger.debug("Found \(totalResults ?? 0) total events. Fetching all pages...")
                        }
                        
                        // Add events from this page to our collection
                        allEvents.append(contentsOf: verifiedEvents)
                        self.logger.debug("Fetched page \(page) (\(verifiedEvents.count) events), total now: \(allEvents.count)")
                        
                        // Print some sample event data for verification
                        if !verifiedEvents.isEmpty {
                            let sampleEvent = verifiedEvents[0].event
                            self.logger.debug("Sample event: '\(sampleEvent.title)' at \(sampleEvent.venue?.name ?? "unknown venue")")
                        }
                        
                        // Check if we need to fetch more pages - exactly like Python implementation
                        if verifiedEvents.count < pageSize {
                            // If we got fewer events than page_size, we're done
                            self.logger.debug("Got \(verifiedEvents.count) events < pageSize (\(pageSize)). No more pages.")
                            hasMorePages = false
                        } else {
                            // Move to next page
                            page += 1
                            
                            // Add a small delay between requests to be nice to the API - exactly like Python
                            self.logger.debug("Scheduling fetch of next page (\(page)) after delay")
                            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                                fetchPage()
                            }
                        }
                    }
                )
                .store(in: &self.cancellables)
        }
        
        // Start the first fetch
        fetchPage()
        
        return subject.eraseToAnyPublisher()
    }
    
    // Store active cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // Generic request method
    private func makeRequest<T: Decodable>(query: String, operationName: String? = nil) -> AnyPublisher<T, Error> {
        // For now, just create a simple empty response
        let mockResponse = """
        {
            "data": {
                "countries": []
            }
        }
        """.data(using: .utf8)!
        
        return Just(mockResponse)
            .setFailureType(to: Error.self)
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    // Generic request method with variables (compatibility method)
    private func makeRequestWithVariables<T: Decodable>(query: String, variables: [String: Any], operationName: String? = nil) -> AnyPublisher<T, Error> {
        // For now, just create a simple empty response
        let mockResponse = """
        {
            "data": {
                "countries": []
            }
        }
        """.data(using: .utf8)!
        
        return Just(mockResponse)
            .setFailureType(to: Error.self)
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    // Get a list of countries and their areas
    func getCountries(forceRefresh: Bool = false) -> AnyPublisher<CountriesResponse, Error> {
        logger.debug("Getting list of countries and areas (forceRefresh: \(forceRefresh))")
        
        // Check for cached data if not forcing refresh
        if !forceRefresh, let url = getCountriesCacheUrl(), FileManager.default.fileExists(atPath: url.path) {
            do {
                let data = try Data(contentsOf: url)
                logger.debug("Loading countries from cache: \(url.path)")
                return Just(data)
                    .setFailureType(to: Error.self)
                    .decode(type: CountriesResponse.self, decoder: JSONDecoder())
                    .eraseToAnyPublisher()
            } catch {
                logger.error("Error loading countries cache: \(error)")
            }
        }
        
        // If forcing refresh or no cache available, fetch from the API
        logger.info(forceRefresh ? "Forcing refresh from API" : "No countries cache available, fetching from the API")
        
        // GraphQL query to fetch countries and areas
        let query = """
        query GetCountriesAndAreas {
          countries {
            id
            name
            areas {
              id
              name
              urlName
              isCountry
            }
          }
        }
        """
        
        guard let url = URL(string: baseURL) else {
            logger.error("Invalid URL: \(baseURL)")
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set headers for the request
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.addValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.addValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.addValue("https://ra.co", forHTTPHeaderField: "Origin")
        request.addValue("https://ra.co/events", forHTTPHeaderField: "Referer")
        
        // Build the payload
        let payload: [String: Any] = [
            "query": query,
            "operationName": "GetCountriesAndAreas"
        ]
        
        // Serialize the payload to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            logger.error("Error serializing request: \(error)")
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        logger.debug("Sending GraphQL request for countries and areas")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { data, response -> Data in
                // Log response details
                if let httpResponse = response as? HTTPURLResponse {
                    self.logger.debug("Countries API response: HTTP \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode != 200 {
                        self.logger.error("API error: HTTP \(httpResponse.statusCode)")
                        
                        // Try to log the error response body
                        if let errorString = String(data: data, encoding: .utf8) {
                            self.logger.error("Error response: \(errorString)")
                        }
                    }
                }
                
                // Save the response for debugging
                self.saveResponseForDebugging(data, filename: "countries_response.json")
                
                return data
            }
            .decode(type: CountriesResponse.self, decoder: JSONDecoder())
            .catch { error -> AnyPublisher<CountriesResponse, Error> in
                self.logger.error("Error fetching countries: \(error.localizedDescription)")
                
                // If there's an error, return an empty response to prevent app crash
                let emptyResponse = CountriesResponse(data: CountriesData(countries: []), errors: nil)
                return Just(emptyResponse)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // Helper to get the cache URL for countries data
    private func getCountriesCacheUrl() -> URL? {
        let fileManager = FileManager.default
        guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            logger.error("Failed to get cache directory")
            return nil
        }
        
        let cacheFolder = cacheDir.appendingPathComponent("RAData", isDirectory: true)
        
        if !fileManager.fileExists(atPath: cacheFolder.path) {
            do {
                try fileManager.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
                logger.debug("Created cache directory at \(cacheFolder.path)")
            } catch {
                logger.error("Error creating cache directory: \(error.localizedDescription)")
                return nil
            }
        }
        
        return cacheFolder.appendingPathComponent("countries_full.json")
    }
    
    // Helper function to save response data for debugging
    private func saveDebugData(_ data: Data, filename: String) {
        do {
            let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let debugFile = cacheDir.appendingPathComponent(filename)
            try data.write(to: debugFile)
            logger.debug("Saved debug data to \(debugFile.path)")
            
            // If it's JSON, try to pretty-print it for easier viewing
            if let json = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
               let prettyStr = String(data: prettyData, encoding: .utf8) {
                
                let prettyFile = cacheDir.appendingPathComponent(filename + ".pretty.json")
                try prettyStr.write(to: prettyFile, atomically: true, encoding: .utf8)
                logger.debug("Saved pretty-printed JSON to \(prettyFile.path)")
            }
        } catch {
            logger.error("Failed to save debug data: \(error)")
        }
    }
    
    // Helper function to verify events are within the requested date range
    private func verifyEventsInDateRange(events: [EventListing], dateFrom: String, dateTo: String) -> [EventListing] {
        // Create a date formatter to parse dates
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // Parse input date range
        guard let fromDate = formatter.date(from: dateFrom),
              let toDate = formatter.date(from: dateTo) else {
            logger.error("Invalid date format in range: \(dateFrom) to \(dateTo)")
            return events // Return all events if we can't parse the dates
        }
        
        // Extract just the date parts for comparison
        let calendar = Calendar.current
        let fromComponents = calendar.dateComponents([.year, .month, .day], from: fromDate)
        let toComponents = calendar.dateComponents([.year, .month, .day], from: toDate)
        
        // Before filtering, log what we're filtering for
        logger.debug("Filtering events to match date range: \(dateFrom) to \(dateTo)")
        
        return events.filter { listing in
            // Try to extract just the date part from the event date
            if let eventDateString = listing.listingDate.components(separatedBy: "T").first,
               let eventDate = formatter.date(from: eventDateString) {
                
                let eventComponents = calendar.dateComponents([.year, .month, .day], from: eventDate)
                
                // Create comparable dates for comparison
                if let eventCompDate = calendar.date(from: eventComponents),
                   let fromCompDate = calendar.date(from: fromComponents),
                   let toCompDate = calendar.date(from: toComponents) {
                    
                    let isInRange = (eventCompDate >= fromCompDate && eventCompDate <= toCompDate)
                    
                    if !isInRange {
                        logger.debug("Filtered out event \(listing.event.title) with date \(eventDateString) (outside requested range)")
                    }
                    
                    return isInRange
                }
            }
            
            // Include the event if we couldn't parse its date (but log it)
            logger.warning("Could not parse date for event: \(listing.event.title), date string: \(listing.listingDate)")
            return true
        }
    }
    
    // Helper function to save response data for debugging
    private func saveResponseForDebugging(_ data: Data, filename: String) {
        #if DEBUG
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.error("Could not access documents directory")
            return
        }
        
        let debugFolder = documentsURL.appendingPathComponent("RADebug", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: debugFolder.path) {
            do {
                try fileManager.createDirectory(at: debugFolder, withIntermediateDirectories: true)
            } catch {
                logger.error("Error creating debug directory: \(error)")
                return
            }
        }
        
        let outputURL = debugFolder.appendingPathComponent(filename)
        
        do {
            try data.write(to: outputURL)
            logger.debug("Saved response to \(outputURL.path)")
        } catch {
            logger.error("Error writing debug file: \(error)")
        }
        #endif
    }
}

extension RAVenue: Equatable {
    static func == (lhs: RAVenue, rhs: RAVenue) -> Bool {
        return lhs.id == rhs.id
    }
}

// Add Equatable conformance to RAEvent
extension RAEvent: Equatable {
    static func == (lhs: RAEvent, rhs: RAEvent) -> Bool {
        return lhs.id == rhs.id
    }
}

// Add Equatable conformance to RAArtist
extension RAArtist: Equatable {
    static func == (lhs: RAArtist, rhs: RAArtist) -> Bool {
        return lhs.id == rhs.id
    }
}