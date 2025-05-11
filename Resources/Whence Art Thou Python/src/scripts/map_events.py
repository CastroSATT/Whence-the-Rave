#!/usr/bin/env python3

"""
Visualize Resident Advisor events on a map.
This script reads events from debug_response.json and creates an interactive map.
"""

import json
import folium
import os
import sys
import pathlib
from datetime import datetime
import geocoder
import ipinfo
from branca.element import Figure, Element

# Define paths for standalone version
SCRIPT_DIR = pathlib.Path(__file__).parent
ROOT_DIR = SCRIPT_DIR.parent.parent
DATA_DIR = ROOT_DIR / "src" / "data"
JSON_DIR = DATA_DIR / "json"

def get_user_location():
    """Get user's current location with coordinates."""
    location = {
        'city': None,
        'country': None,
        'lat': None,
        'lng': None
    }
    
    try:
        # First try ipinfo.io which gives country and city
        g = ipinfo.getHandler()
        details = g.getDetails()
        if details.city:
            location['city'] = details.city
            location['country'] = details.country_name
            # Get coordinates from ipinfo
            if hasattr(details, 'latitude') and hasattr(details, 'longitude'):
                location['lat'] = float(details.latitude)
                location['lng'] = float(details.longitude)
            
            print(f"Detected location: {location['city']}, {location['country']}")
    except Exception as e:
        print(f"Error with ipinfo: {e}")
    
    # If we don't have coordinates, try geocoder
    if location['lat'] is None or location['lng'] is None:
        try:
            g = geocoder.ip('me')
            if g.ok:
                if location['city'] is None:
                    location['city'] = g.city
                    location['country'] = g.country
                
                location['lat'] = g.lat
                location['lng'] = g.lng
                print(f"Got coordinates via geocoder: {location['lat']}, {location['lng']}")
        except Exception as e:
            print(f"Error with geocoder: {e}")
    
    # If still no coordinates but we have city, geocode the city name
    if (location['lat'] is None or location['lng'] is None) and location['city']:
        try:
            g = geocoder.osm(f"{location['city']}, {location['country']}")
            if g.ok:
                location['lat'] = g.lat
                location['lng'] = g.lng
                print(f"Got coordinates for {location['city']} via geocoding: {location['lat']}, {location['lng']}")
        except Exception as e:
            print(f"Error geocoding city: {e}")
            
    return location

def extract_date_info_from_events(events):
    """Extract date information from events to create a title."""
    if not events:
        return "Events Map - No Date Information"
    
    dates = []
    locations = set()
    
    for event in events:
        # Extract event date
        event_info = event.get("event", {})
        date_str = event_info.get("date", "")
        if date_str:
            try:
                date_obj = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
                dates.append(date_obj)
            except (ValueError, TypeError):
                pass
        
        # Extract location/area
        venue_info = event_info.get("venue", {})
        if venue_info and venue_info.get("area") and venue_info["area"].get("name"):
            locations.add(venue_info["area"]["name"])
    
    # Create title based on dates and locations
    date_part = ""
    if dates:
        dates.sort()  # Sort dates chronologically
        if len(dates) == 1:
            date_part = f"Events for {dates[0].strftime('%a, %b %d, %Y')}"
        else:
            date_part = f"Events from {dates[0].strftime('%a, %b %d, %Y')} to {dates[-1].strftime('%a, %b %d, %Y')}"
    else:
        date_part = "Events"
    
    location_part = ""
    if len(locations) == 1:
        location_part = f"in {next(iter(locations))}"
    elif len(locations) > 1:
        location_part = f"in multiple locations"
    
    return f"{date_part} {location_part}"

def load_events_from_debug_file():
    """Load events from debug_response.json file."""
    file_path = ROOT_DIR / "debug_response.json"
    try:
        with open(file_path, "r") as f:
            data = json.load(f)
        
        if (
            "data" in data 
            and "eventListingsWithBumps" in data["data"] 
            and "eventListings" in data["data"]["eventListingsWithBumps"]
        ):
            return data["data"]["eventListingsWithBumps"]["eventListings"]["data"]
        else:
            print("Error: Unexpected data structure in debug_response.json")
            return []
    except (FileNotFoundError, json.JSONDecodeError) as e:
        print(f"Error loading debug file: {e}")
        print("Make sure to run nearby_events.py first to generate the debug_response.json file")
        return []

def format_event_time(time_str):
    """Format time string to a readable format."""
    if not time_str:
        return ""
    try:
        time_obj = datetime.fromisoformat(time_str.replace('Z', '+00:00'))
        return time_obj.strftime("%H:%M")
    except (ValueError, TypeError):
        return ""

def create_event_map(events, user_location=None):
    """Create an interactive map with event locations."""
    # Find center of map (average of valid coordinates)
    valid_coords = []
    for event in events:
        venue = event.get("event", {}).get("venue", {})
        if venue and "location" in venue:
            lat = venue["location"].get("latitude", 0)
            lng = venue["location"].get("longitude", 0)
            if lat != 0 and lng != 0:  # Skip venues with 0,0 coordinates
                valid_coords.append((lat, lng))
    
    # If we have user location, include it in centering calculation
    if user_location and user_location['lat'] and user_location['lng']:
        valid_coords.append((user_location['lat'], user_location['lng']))
    
    if not valid_coords:
        # Default to London center if no valid coordinates
        center = [51.5074, -0.1278]
    else:
        avg_lat = sum(lat for lat, _ in valid_coords) / len(valid_coords)
        avg_lng = sum(lng for _, lng in valid_coords) / len(valid_coords)
        center = [avg_lat, avg_lng]
    
    # Create a figure to hold the map with title area
    fig = Figure(width="100%", height="100%")
    
    # Create map
    event_map = folium.Map(location=center, zoom_start=12, tiles="OpenStreetMap")
    
    # Extract date information for title
    map_title = extract_date_info_from_events(events)
    
    # Add markers for each event
    for event in events:
        event_info = event.get("event", {})
        venue_info = event_info.get("venue", {})
        
        if not venue_info or "location" not in venue_info:
            continue
            
        lat = venue_info["location"].get("latitude", 0)
        lng = venue_info["location"].get("longitude", 0)
        
        # Skip venues with 0,0 coordinates (TBA locations)
        if lat == 0 and lng == 0:
            continue
            
        event_title = event_info.get("title", "Unknown event")
        venue_name = venue_info.get("name", "Unknown venue")
        
        # Format event date and time
        date_str = event_info.get("date", "")
        date_formatted = ""
        try:
            date_obj = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
            date_formatted = date_obj.strftime("%a, %b %d, %Y")
        except (ValueError, TypeError):
            date_formatted = date_str
        
        # Get start and end times
        start_time = format_event_time(event_info.get("startTime", ""))
        end_time = format_event_time(event_info.get("endTime", ""))
        
        # Format time range
        time_range = ""
        if start_time and end_time:
            time_range = f"{start_time} - {end_time}"
        elif start_time:
            time_range = f"From {start_time}"
        
        # Get artists
        artists = []
        if event_info.get("artists"):
            artists = [artist["name"] for artist in event_info["artists"]]
        artists_str = ", ".join(artists)
        
        # Get interest count
        interest_count = event_info.get("interestedCount", 0)
        
        # Determine marker color based on popularity
        if interest_count >= 500:
            marker_color = "red"
            popularity = "Very Popular"
        elif interest_count >= 100:
            marker_color = "orange"
            popularity = "Popular"
        else:
            marker_color = "blue"
            popularity = "Standard"
        
        # Create tooltip with basic info
        tooltip = f"{event_title} @ {venue_name}<br>{date_formatted} {time_range}"
        
        # Create popup with detailed info
        event_url = f"https://ra.co{event_info['contentUrl']}" if event_info.get('contentUrl') else ""
        popup_html = f"""
        <div style="width: 250px; max-height: 300px; overflow-y: auto;">
            <h3>{event_title}</h3>
            <p><strong>Venue:</strong> {venue_name}</p>
            <p><strong>Date:</strong> {date_formatted}</p>
            <p><strong>Time:</strong> {time_range}</p>
            <p><strong>Artists:</strong> {artists_str}</p>
            <p><strong>Interested:</strong> {interest_count}</p>
            <p><a href="{event_url}" target="_blank">View on Resident Advisor</a></p>
        </div>
        """
        
        # Add marker to map
        folium.Marker(
            location=[lat, lng],
            popup=folium.Popup(popup_html, max_width=300),
            tooltip=tooltip,
            icon=folium.Icon(color=marker_color, icon="music", prefix="fa")
        ).add_to(event_map)
    
    # Add user location marker if available
    if user_location and user_location['lat'] and user_location['lng']:
        # Add user marker
        folium.Marker(
            location=[user_location['lat'], user_location['lng']],
            popup=f"Your location: {user_location['city']}, {user_location['country']}",
            tooltip="Your location",
            icon=folium.Icon(color="green", icon="user", prefix="fa")
        ).add_to(event_map)
        
        # Add distance circles (1km, 3km, 5km)
        folium.Circle(
            location=[user_location['lat'], user_location['lng']],
            radius=1000,  # 1km in meters
            color='green',
            fill=True,
            fill_opacity=0.1,
            tooltip="1km radius"
        ).add_to(event_map)
        
        folium.Circle(
            location=[user_location['lat'], user_location['lng']],
            radius=3000,  # 3km in meters
            color='green',
            fill=True,
            fill_opacity=0.05,
            tooltip="3km radius"
        ).add_to(event_map)
        
        folium.Circle(
            location=[user_location['lat'], user_location['lng']],
            radius=5000,  # 5km in meters
            color='green',
            fill=True,
            fill_opacity=0.02,
            tooltip="5km radius"
        ).add_to(event_map)
    
    # Add title to map
    title_html = f'''
    <div style="position: fixed; 
                top: 10px; left: 50px; width: 80%; 
                background-color: rgba(255, 255, 255, 0.8);
                border-radius: 10px; padding: 10px; z-index: 9999; text-align: center;">
        <h3>{map_title}</h3>
    </div>
    '''
    event_map.get_root().html.add_child(folium.Element(title_html))
    
    # Add legend
    legend_html = '''
    <div style="position: fixed; 
                bottom: 50px; right: 50px; 
                background-color: rgba(255, 255, 255, 0.8);
                border-radius: 10px; padding: 10px; z-index: 9999;">
        <p><i class="fa fa-map-marker" style="color:red"></i> Very Popular (500+ interested)</p>
        <p><i class="fa fa-map-marker" style="color:orange"></i> Popular (100-500 interested)</p>
        <p><i class="fa fa-map-marker" style="color:blue"></i> Standard (<100 interested)</p>
        <p><i class="fa fa-map-marker" style="color:green"></i> Your Location</p>
    </div>
    '''
    event_map.get_root().html.add_child(folium.Element(legend_html))
    
    # Save map to file
    map_file = ROOT_DIR / "ra_events_map.html"
    event_map.save(str(map_file))
    
    print(f"Map saved to {map_file}")
    
    # Try to open the map in the default browser
    try:
        import webbrowser
        webbrowser.open(f"file://{map_file.resolve()}")
    except Exception as e:
        print(f"Could not open map in browser: {e}")
    
    return str(map_file)

def main():
    """Main function to create a map from events."""
    print("Loading events from debug file...")
    events = load_events_from_debug_file()
    
    if not events:
        print("No events found to map. Please run nearby_events.py first.")
        return
    
    print(f"Found {len(events)} events to map.")
    
    # Get user location
    print("Detecting your location...")
    user_location = get_user_location()
    
    # Create the map
    print("Creating map...")
    map_file = create_event_map(events, user_location)
    
    print(f"Map created successfully at {map_file}")

if __name__ == "__main__":
    main() 