#!/usr/bin/env python3

import json
import requests
import time
import argparse
import sys
import pathlib
from tabulate import tabulate

# Define paths for standalone version
SCRIPT_DIR = pathlib.Path(__file__).parent
ROOT_DIR = SCRIPT_DIR.parent.parent
DATA_DIR = ROOT_DIR / "src" / "data"
JSON_DIR = DATA_DIR / "json"

def print_section(title):
    """Print a section header."""
    print("\n" + "=" * 80)
    print(f" {title} ".center(80, "="))
    print("=" * 80 + "\n")

def setup_request_headers():
    """Set up common request headers."""
    return {
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "Accept": "application/json",
        "Accept-Language": "en-US,en;q=0.9",
        "Origin": "https://ra.co",
        "Referer": "https://ra.co/events",
    }

def execute_query(query, variables=None, operation_name=None):
    """Execute a GraphQL query and return the response."""
    url = "https://ra.co/graphql"
    headers = setup_request_headers()
    
    payload = {
        "query": query
    }
    
    if variables:
        payload["variables"] = variables
    
    if operation_name:
        payload["operationName"] = operation_name
    
    try:
        # Create a session to maintain cookies
        session = requests.Session()
        
        # First visit the main site to get any cookies needed
        session.get("https://ra.co")
        
        # Make the API request
        response = session.post(url, json=payload, headers=headers)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error executing query: {e}")
        return {"errors": [{"message": str(e)}]}

def save_response(data, filename):
    """Save response data to a JSON file."""
    try:
        filepath = JSON_DIR / filename
        JSON_DIR.mkdir(exist_ok=True, parents=True)
        
        with open(filepath, "w") as f:
            json.dump(data, f, indent=2)
        print(f"Response saved to {filepath}")
    except Exception as e:
        print(f"Error saving response: {e}")

def display_response(data, query_name):
    """Display a summary of the response."""
    if "errors" in data:
        print(f"❌ Query failed: {query_name}")
        for error in data["errors"]:
            print(f"  - {error['message']}")
        return False
    
    print(f"✅ Query successful: {query_name}")
    
    if "data" in data:
        # Try to extract some basic info from the response
        for key, value in data["data"].items():
            if isinstance(value, list):
                print(f"  - Retrieved {len(value)} {key}")
            elif isinstance(value, dict):
                if "data" in value and isinstance(value["data"], list):
                    print(f"  - Retrieved {len(value['data'])} {key} items")
                elif "totalResults" in value:
                    print(f"  - Total results: {value['totalResults']}")
                else:
                    print(f"  - Retrieved {key} data")
    
    return True

def get_all_areas():
    """Get all available areas."""
    query = """
    query GetAreas {
      areas {
        id
        name
        country {
          id
          name
        }
      }
    }
    """
    
    print("Fetching all areas...")
    response = execute_query(query)
    success = display_response(response, "GetAreas")
    
    if success:
        save_response(response, "areas_full.json")
    
    return response

def get_all_countries():
    """Get all available countries."""
    query = """
    query GetCountries {
      countries {
        id
        name
        areas {
          id
          name
        }
      }
    }
    """
    
    print("Fetching all countries...")
    response = execute_query(query)
    success = display_response(response, "GetCountries")
    
    if success:
        save_response(response, "countries_full.json")
    
    return response

def get_events_by_area(area_id, date_from, date_to, page=1, page_size=25, sort="LATEST"):
    """Get events by area and date range."""
    query = """
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
      }
    }
    """
    
    # Construct variables in the format used by the website
    variables = {
        "areaId": int(area_id),
        "filterOptions": {
            "genre": True,
            "eventType": True
        },
        "filters": {
            "areas": {"eq": int(area_id)},
            "listingDate": {"gte": date_from, "lte": date_to}
        },
        "page": page,
        "pageSize": page_size
    }
    
    # Add sort using the format from the provided example
    sort_mapping = {
        "LATEST": {
            "listingDate": {"order": "ASCENDING"},
            "score": {"order": "DESCENDING"},
            "titleKeyword": {"order": "ASCENDING"}
        },
        "POPULAR": {
            "score": {"order": "DESCENDING"},
            "listingDate": {"order": "ASCENDING"},
            "titleKeyword": {"order": "ASCENDING"}
        },
        "ALPHABETICAL": {
            "titleKeyword": {"order": "ASCENDING"},
            "score": {"order": "DESCENDING"},
            "listingDate": {"order": "ASCENDING"}
        }
    }
    
    if sort in sort_mapping:
        variables["sort"] = sort_mapping[sort]
    
    print(f"Fetching events for area {area_id} from {date_from} to {date_to}...")
    response = execute_query(query, variables, "GET_EVENT_LISTINGS_WITH_BUMPS")
    success = display_response(response, "GET_EVENT_LISTINGS_WITH_BUMPS")
    
    if success:
        save_response(response, f"events_area_{area_id}.json")
        # Also save to debug_response.json for map generation
        debug_file = ROOT_DIR / "debug_response.json"
        with open(debug_file, "w") as f:
            json.dump(response, f, indent=2)
    
    return response

def get_event_by_id(event_id):
    """Get detailed information about a specific event."""
    query = """
    query GetEventDetails($id: ID!) {
      event(id: $id) {
        id
        title
        date
        contentUrl
        interestedCount
        venue {
          id
          name
          address
          contentUrl
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
    
    variables = {
        "id": event_id
    }
    
    print(f"Fetching details for event {event_id}...")
    response = execute_query(query, variables, "GetEventDetails")
    success = display_response(response, "GetEventDetails")
    
    if success:
        save_response(response, f"event_details_{event_id}.json")
    
    return response

def get_venue_by_id(venue_id):
    """Get detailed information about a specific venue."""
    query = """
    query GetVenueDetails($id: ID!) {
      venue(id: $id) {
        id
        name
        address
        contentUrl
        location {
          latitude
          longitude
        }
      }
    }
    """
    
    variables = {
        "id": venue_id
    }
    
    print(f"Fetching details for venue {venue_id}...")
    response = execute_query(query, variables, "GetVenueDetails")
    success = display_response(response, "GetVenueDetails")
    
    if success:
        save_response(response, f"venue_details_{venue_id}.json")
    
    return response

def main():
    """Main function to demonstrate API usage."""
    parser = argparse.ArgumentParser(description="Resident Advisor API Client")
    parser.add_argument("--area", type=int, help="Area ID to search for events")
    parser.add_argument("--date-from", help="Start date in YYYY-MM-DD format")
    parser.add_argument("--date-to", help="End date in YYYY-MM-DD format")
    parser.add_argument("--event", type=int, help="Event ID to get details for")
    parser.add_argument("--venue", type=int, help="Venue ID to get details for")
    parser.add_argument("--countries", action="store_true", help="Get all countries")
    parser.add_argument("--areas", action="store_true", help="Get all areas")
    
    args = parser.parse_args()
    
    if args.area and args.date_from and args.date_to:
        get_events_by_area(args.area, args.date_from, args.date_to)
    elif args.event:
        get_event_by_id(args.event)
    elif args.venue:
        get_venue_by_id(args.venue)
    elif args.countries:
        get_all_countries()
    elif args.areas:
        get_all_areas()
    else:
        parser.print_help()

if __name__ == "__main__":
    main() 