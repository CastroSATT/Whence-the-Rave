#!/usr/bin/env python3

"""
Find events near your current location or by specified area/country name.
"""

import json
import requests
import datetime
import argparse
from tabulate import tabulate
import sys
import os
import pathlib
import ipinfo
import geocoder
import importlib.util
import time

# Define paths for standalone version
SCRIPT_DIR = pathlib.Path(__file__).parent
ROOT_DIR = SCRIPT_DIR.parent.parent
DATA_DIR = ROOT_DIR / "src" / "data"
JSON_DIR = DATA_DIR / "json"
CSV_DIR = DATA_DIR / "csv"

# Available sort options
SORT_OPTIONS = ["LATEST", "POPULAR", "ALPHABETICAL"]

def get_events_for_area(area_id, date_from, date_to, page=1, page_size=25, sort="LATEST"):
    """Get events by area and date range with pagination."""
    url = "https://ra.co/graphql"
    headers = {
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "application/json, text/plain, */*",
        "Accept-Language": "en-US,en;q=0.9",
        "Origin": "https://ra.co",
        "Referer": "https://ra.co/events/uk/london",
    }
    
    # Use the actual query used by RA's website
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
    
    # Format dates to match what's expected by the API
    date_from_obj = datetime.datetime.strptime(date_from, "%Y-%m-%d").date()
    date_to_obj = datetime.datetime.strptime(date_to, "%Y-%m-%d").date()
    
    # Check if we're looking for a specific day (today)
    is_single_day = date_from == date_to
    
    # Construct variables in the format used by the website
    variables = {
        "areaId": int(area_id),
        "filterOptions": {
            "genre": True,
            "eventType": True
        },
        "filters": {
            "areas": {"eq": int(area_id)}
        },
        "page": page,
        "pageSize": page_size
    }
    
    # Add date filtering based on the format in the provided example
    if is_single_day:
        variables["filters"]["listingDate"] = {
            "gte": date_from,
            "lte": date_from
        }
    else:
        variables["filters"]["listingDate"] = {
            "gte": date_from,
            "lte": date_to
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
    
    payload = {
        "query": query,
        "variables": variables,
        "operationName": "GET_EVENT_LISTINGS_WITH_BUMPS"
    }
    
    try:
        # Create a session to maintain cookies
        session = requests.Session()
        
        # First visit the main site to get any cookies needed
        session.get("https://ra.co")
        
        # Make the API request
        response = session.post(url, json=payload, headers=headers)
        response.raise_for_status()
        
        # Parse the response
        data = response.json()
        
        # Extract the event listings
        if "data" in data and "eventListingsWithBumps" in data["data"]:
            event_listings = data["data"]["eventListingsWithBumps"]["eventListings"]
            events = event_listings["data"]
            total_results = event_listings["totalResults"]
            
            print(f"\nFound {total_results} events in {area_id} ({page_size} per page, showing page {page})")
            
            return events, data
        else:
            print("Error: Unexpected response structure")
            print(f"Response: {data}")
            return [], None
    
    except requests.exceptions.RequestException as e:
        print(f"Error fetching events: {e}")
        return [], None

def find_area_by_name(name):
    """Find an area ID by name."""
    if not name:
        return None, None, None
    
    # Load the countries data
    countries_file = JSON_DIR / "countries_full.json"
    if not countries_file.exists():
        print(f"Error: {countries_file} not found. Please run the update_area_database.py script first.")
        return None, None, None
    
    try:
        with open(countries_file, "r") as f:
            countries_data = json.load(f)
        
        if "data" not in countries_data or "countries" not in countries_data["data"]:
            print("Error: Invalid countries data format.")
            return None, None, None
        
        countries = countries_data["data"]["countries"]
        
        # First check if the name is a country
        for country in countries:
            if country["name"].lower() == name.lower():
                # Find the "All" area for this country
                for area in country["areas"]:
                    if area["name"] == "All" and area["isCountry"]:
                        return area["id"], area["name"], country["name"]
        
        # If not a country, check all areas
        exact_matches = []
        partial_matches = []
        
        for country in countries:
            for area in country["areas"]:
                if area["name"].lower() == name.lower():
                    exact_matches.append((area["id"], area["name"], country["name"]))
                elif name.lower() in area["name"].lower():
                    partial_matches.append((area["id"], area["name"], country["name"]))
        
        # Return the first exact match if found
        if exact_matches:
            return exact_matches[0]
        
        # Return the first partial match if found
        if partial_matches:
            return partial_matches[0]
        
        # No matches found
        return None, None, None
    
    except Exception as e:
        print(f"Error finding area: {e}")
        return None, None, None

def get_area_info(area_id):
    """Get information about an area by ID."""
    url = "https://ra.co/graphql"
    headers = {
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "application/json, text/plain, */*",
        "Accept-Language": "en-US,en;q=0.9",
    }
    
    query = """
    query GetAreaInfo($id: ID!) {
      area(id: $id) {
        id
        name
        country {
          id
          name
        }
      }
    }
    """
    
    variables = {
        "id": area_id
    }
    
    payload = {
        "query": query,
        "variables": variables,
        "operationName": "GetAreaInfo"
    }
    
    try:
        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error fetching area info: {e}")
        return None

def get_current_location():
    """Get the user's current location based on IP address."""
    try:
        # Try using ipinfo first
        try:
            handler = ipinfo.getHandler()
            details = handler.getDetails()
            return details.city, details.country_name
        except Exception as e:
            print(f"ipinfo failed: {e}, trying geocoder...")
        
        # Fall back to geocoder
        g = geocoder.ip('me')
        if g.ok:
            return g.city, g.country
    except Exception as e:
        print(f"Could not detect location: {e}")
    
    return None, None

def display_events(events, show_urls=True):
    """Display events in a nicely formatted table."""
    if not events:
        print("No events found for the selected criteria.")
        return
        
    table_data = []
    
    for event_listing in events:
        event_info = event_listing.get("event", {})
        venue_info = event_info.get("venue", {})
        venue_name = venue_info.get("name", "Unknown venue")
        
        # Extract venue area
        venue_area = ""
        if venue_info.get("area") and venue_info["area"].get("name"):
            venue_area = venue_info["area"]["name"]
        
        # Extract artists
        artists = []
        if event_info.get("artists"):
            artists = [artist["name"] for artist in event_info["artists"]]
        artists_str = ", ".join(artists[:3])
        if len(artists) > 3:
            artists_str += f" +{len(artists) - 3} more"
        
        # Format event date and time
        date_str = event_info.get("date", "")
        try:
            date_obj = datetime.datetime.fromisoformat(date_str.replace('Z', '+00:00'))
            date_formatted = date_obj.strftime("%a, %b %d, %Y")
            
            start_time = event_info.get("startTime", "")
            if start_time:
                start_time_obj = datetime.datetime.fromisoformat(start_time.replace('Z', '+00:00'))
                time_formatted = start_time_obj.strftime("%H:%M")
                date_formatted += f" {time_formatted}"
        except (ValueError, TypeError):
            date_formatted = date_str
        
        # Format listing date (when it appears on the site)
        listing_date = event_listing.get("listingDate", "")
        if listing_date:
            try:
                listing_date_obj = datetime.datetime.fromisoformat(listing_date.replace('Z', '+00:00'))
                listing_date_formatted = listing_date_obj.strftime("%Y-%m-%d")
            except (ValueError, TypeError):
                listing_date_formatted = listing_date
        else:
            listing_date_formatted = ""
        
        event_url = f"https://ra.co{event_info['contentUrl']}" if event_info.get('contentUrl') else ""
        interested_count = event_info.get("interestedCount", 0)
        
        row = [
            event_info.get("title", "Unknown event"),
            venue_name,
            venue_area if venue_area else venue_info.get("address", ""),
            date_formatted,
            listing_date_formatted,
            artists_str,
            interested_count
        ]
        
        if show_urls:
            row.append(event_url)
            
        table_data.append(row)
    
    headers = ["Event", "Venue", "Location", "Event Date", "Listed Date", "Artists", "Interested"]
    if show_urls:
        headers.append("URL")
    
    print(tabulate(table_data, headers=headers, tablefmt="grid"))

def generate_map():
    """Generate a map from the last API response."""
    try:
        # Check if the map_events module is available
        map_script_path = pathlib.Path(__file__).parent / "map_events.py"
        if not map_script_path.exists():
            print("\nError: map_events.py script not found.")
            return False
        
        # Use importlib to dynamically import the map_events module
        spec = importlib.util.spec_from_file_location("map_events", map_script_path)
        map_module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(map_module)
        
        # Run the map generation function
        print("\nGenerating map from events...")
        map_module.main()
        return True
    except Exception as e:
        print(f"\nError generating map: {e}")
        return False

def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Find events near you or by location on Resident Advisor")
    
    location_group = parser.add_mutually_exclusive_group()
    location_group.add_argument("--area", type=str, help="Area name to search for events")
    location_group.add_argument("--area-id", type=str, help="Area ID to search for events")
    location_group.add_argument("--nearby", action="store_true", help="Use your current location")
    
    date_group = parser.add_mutually_exclusive_group()
    date_group.add_argument("--today", action="store_true", help="Show only today's events")
    date_group.add_argument("--yesterday", action="store_true", help="Show only yesterday's events")
    date_group.add_argument("--tomorrow", action="store_true", help="Show only tomorrow's events")
    date_group.add_argument("--days", type=int, default=7, help="Number of days to look ahead (default: 7)")
    date_group.add_argument("--day", type=int, help="Specific day of the month (requires --month and --year)")
    
    parser.add_argument("--page", type=int, default=1, help="Page number (default: 1)")
    parser.add_argument("--page-size", type=int, default=25, help="Results per page (default: 25, max: 50)")
    parser.add_argument("--sort", type=str, default="LATEST", choices=SORT_OPTIONS, help="Sort order (default: LATEST)")
    parser.add_argument("--save", action="store_true", help="Save results to a JSON file")
    parser.add_argument("--no-urls", action="store_true", help="Hide URLs in the output")
    parser.add_argument("--year", type=int, help="Specify the year for the date range (default: current year)")
    parser.add_argument("--month", type=int, help="Specify the month for the date range (default: current month)")
    parser.add_argument("--map", action="store_true", help="Generate a map of event locations")
    
    return parser.parse_args()

def get_all_events_for_area(area_id, date_from, date_to, sort="LATEST", page_size=100):
    """Get all events by making multiple API calls and aggregating results."""
    all_events = []
    all_data = None
    page = 1
    total_results = None
    
    print("\nFetching all events (this may take a moment)...")
    
    while True:
        # Make API call for current page
        events_response, response_data = get_events_for_area(area_id, date_from, date_to, page, page_size, sort)
        
        if not events_response:
            break
            
        # Get total results count if first page
        if page == 1:
            total_results = response_data["data"]["eventListingsWithBumps"]["eventListings"]["totalResults"]
            print(f"Found {total_results} total events. Fetching all pages...")
            all_data = response_data
        else:
            # Update the data with all events
            all_data["data"]["eventListingsWithBumps"]["eventListings"]["data"].extend(events_response)
        
        # Add events from this page to our collection
        all_events.extend(events_response)
        print(f"Fetched page {page} ({len(events_response)} events)")
        
        # If we got fewer events than page_size, we're done
        if len(events_response) < page_size:
            break
            
        # Move to next page
        page += 1
        
        # Add a small delay between requests to be nice to the API
        time.sleep(0.5)
    
    # Save all events to debug file
    if all_data:
        debug_file = ROOT_DIR / "debug_response.json"
        with open(debug_file, "w") as f:
            json.dump(all_data, f, indent=2)
    
    print(f"\nFetched {len(all_events)} events total.")
    return all_events

def main():
    args = parse_arguments()
    
    # Determine the area to search
    area_id = None
    area_name = None
    country_name = None
    
    if args.area_id:
        # If area ID is provided, use it directly
        area_id = args.area_id
        area_info = get_area_info(area_id)
        if area_info and "data" in area_info and area_info["data"]["area"]:
            area_name = area_info["data"]["area"]["name"]
            country_name = area_info["data"]["area"]["country"]["name"]
    
    elif args.area:
        # If area name is provided, look it up
        area_id, area_name, country_name = find_area_by_name(args.area)
        if not area_id:
            print(f"Could not find area with name '{args.area}'. Please check the spelling or use an area ID.")
            sys.exit(1)
    
    elif args.nearby:
        # If nearby flag is set, use current location
        city, country = get_current_location()
        if city:
            area_id, area_name, country_name = find_area_by_name(city)
            if not area_id:
                # If city not found, try country
                area_id, area_name, country_name = find_area_by_name(country)
        
        if not area_id:
            print("Could not determine your location. Please specify an area name or ID.")
            sys.exit(1)
    
    else:
        # If no location specified, default to using current location
        print("No location specified, using your current location...")
        city, country = get_current_location()
        if city:
            area_id, area_name, country_name = find_area_by_name(city)
            if not area_id:
                # If city not found, try country
                area_id, area_name, country_name = find_area_by_name(country)
        
        if not area_id:
            print("Could not determine your location. Please specify an area name or ID.")
            sys.exit(1)
    
    # Set date range
    if args.year and args.month and args.day:
        # Use specific year, month, and day if provided
        try:
            start_date = datetime.date(args.year, args.month, args.day)
        except ValueError:
            print(f"Invalid date: {args.year}-{args.month}-{args.day}")
            sys.exit(1)
    else:
        # Use current date
        now = datetime.datetime.now()
        start_date = datetime.date(now.year, now.month, now.day)
    
    # Create date range based on flags
    if args.today:
        date_from = start_date.strftime("%Y-%m-%d")
        date_to = date_from
        print(f"\nSearching for events in {area_name}, {country_name}")
        print(f"Date: TODAY ({date_from})")
    elif args.yesterday:
        yesterday = start_date - datetime.timedelta(days=1)
        date_from = yesterday.strftime("%Y-%m-%d")
        date_to = date_from
        print(f"\nSearching for events in {area_name}, {country_name}")
        print(f"Date: YESTERDAY ({date_from})")
    elif args.tomorrow:
        tomorrow = start_date + datetime.timedelta(days=1)
        date_from = tomorrow.strftime("%Y-%m-%d")
        date_to = date_from
        print(f"\nSearching for events in {area_name}, {country_name}")
        print(f"Date: TOMORROW ({date_from})")
    else:
        date_from = start_date.strftime("%Y-%m-%d")
        end_date = start_date + datetime.timedelta(days=args.days)
        date_to = end_date.strftime("%Y-%m-%d")
        print(f"\nSearching for events in {area_name}, {country_name}")
        print(f"Date range: {date_from} to {date_to} ({args.days} days)")
    
    # Always use the new function to get all events
    events = get_all_events_for_area(area_id, date_from, date_to, args.sort)
    
    # Display events
    display_events(events, not args.no_urls)
    
    # Generate map if requested
    if args.map:
        print("\nGenerating map of events...")
        if not generate_map():
            print("Would you like to generate a map of these events? (y/n)")
            if input().lower() == 'y':
                generate_map()

if __name__ == "__main__":
    main() 