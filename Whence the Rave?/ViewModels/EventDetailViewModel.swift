import Foundation
import Combine
import SwiftUI

class EventDetailViewModel: ObservableObject {
    @Published var event: RAEvent?
    @Published var isLoading = false
    @Published var error: String?
    
    private let apiClient = RAApiClient.shared
    private var cancellables = Set<AnyCancellable>()
    private let logger = AppLogger.shared
    
    func fetchEvent(id: String) {
        guard !id.isEmpty else {
            self.error = "Invalid event ID"
            return
        }
        
        if event?.id == id, error == nil {
            return
        }
        
        isLoading = true
        error = nil
        
        // Create the GraphQL query
        let query = """
        query GetEventDetails($id: ID!) {
          event(id: $id) {
            id
            title
            date
            startTime
            endTime
            contentUrl
            flyerFront
            isTicketed
            interestedCount
            venue {
              id
              name
              contentUrl
              address
              location {
                latitude
                longitude
              }
            }
            artists {
              id
              name
              contentUrl
            }
          }
        }
        """
        
        let variables: [String: Any] = ["id": id]
        
        // Setup payload
        let payload: [String: Any] = [
            "query": query,
            "variables": variables,
            "operationName": "GetEventDetails"
        ]
        
        // Execute the query using performGraphQLRequest
        apiClient.performGraphQLRequest(payload: payload) { [weak self] (data, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.error = "Failed to load event: \(error.localizedDescription)"
                    self.logger.error("Failed to fetch event \(id): \(error)")
                    return
                }
                
                guard let data = data else {
                    self.error = "No data received"
                    self.logger.error("No data received for event \(id)")
                    return
                }
                
                do {
                    // Try to parse the response
                    let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    self.logger.debug("Received event data: \(String(describing: jsonResponse))")
                    
                    if let eventData = jsonResponse?["data"] as? [String: Any],
                       let eventDict = eventData["event"] as? [String: Any] {
                        // Convert to JSON data and decode
                        let jsonData = try JSONSerialization.data(withJSONObject: eventDict)
                        let event = try JSONDecoder().decode(RAEvent.self, from: jsonData)
                        
                        self.event = event
                        self.logger.info("Loaded event: \(event.title)")
                    } else {
                        self.error = "Event not found"
                        self.logger.error("Event data not found in response")
                    }
                } catch {
                    self.error = "Failed to parse event data: \(error.localizedDescription)"
                    self.logger.error("Failed to parse event data: \(error)")
                }
            }
        }
    }
} 