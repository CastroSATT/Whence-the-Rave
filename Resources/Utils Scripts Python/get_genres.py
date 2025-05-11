#!/usr/bin/env python3

"""
Standalone script to download all music genres from Resident Advisor (RA.co)
and save them to a JSON file.

This script doesn't require any other files from the project.
"""

import json
import requests
import os
import datetime
from pathlib import Path

def download_genres():
    """Download all genres from Resident Advisor GraphQL API."""
    print("Downloading genres from Resident Advisor...")
    
    url = "https://ra.co/graphql"
    headers = {
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "application/json, text/plain, */*",
        "Accept-Language": "en-US,en;q=0.9",
        "Origin": "https://ra.co",
        "Referer": "https://ra.co/events",
    }
    
    # Direct query to fetch all genres
    query = """
    query GetAllGenres {
      genres {
        id
        name
      }
    }
    """
    
    payload = {
        "query": query,
        "operationName": "GetAllGenres"
    }
    
    try:
        # Create a session to maintain cookies
        session = requests.Session()
        
        # First visit the main site to get any cookies needed
        print("Visiting RA.co site to set up cookies...")
        session.get("https://ra.co")
        
        # Make the API request
        print("Fetching genres data from API...")
        response = session.post(url, json=payload, headers=headers)
        response.raise_for_status()
        
        # Parse the response
        data = response.json()
        
        # Check if response has the expected structure
        if not data or "data" not in data:
            print("Error: Invalid response structure")
            if "errors" in data:
                print(f"API errors: {data['errors']}")
            return None
            
        if "genres" not in data["data"] or data["data"]["genres"] is None:
            print("Error: Genres data is missing in the response")
            if "errors" in data:
                print(f"API errors: {data['errors']}")
            return None
        
        # Extract genres
        genres = data["data"]["genres"]
        print(f"Successfully downloaded {len(genres)} genres")
        
        return genres
        
    except requests.exceptions.RequestException as e:
        print(f"Error fetching genres: {e}")
        return None
    except Exception as e:
        print(f"Unexpected error: {e}")
        return None

def save_genres(genres, output_file=None):
    """Save the genres to a JSON file."""
    if not genres:
        print("No genres to save")
        return
    
    # Use genres.json in the current directory if no file specified
    if not output_file:
        output_file = Path("genres.json")
    
    # Create directories if needed
    os.makedirs(os.path.dirname(output_file) if os.path.dirname(output_file) else ".", exist_ok=True)
    
    # Format the genres into a cleaner structure
    genres_data = {
        "total": len(genres),
        "date_updated": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "genres": sorted(genres, key=lambda x: x["name"])
    }
    
    try:
        with open(output_file, "w") as f:
            json.dump(genres_data, f, indent=2)
        print(f"Genres saved to {output_file}")
        return True
    except Exception as e:
        print(f"Error saving genres to file: {e}")
        return False

def display_genres(genres):
    """Display a table of genres with their IDs."""
    if not genres:
        print("No genres to display")
        return
    
    print("\nResident Advisor Music Genres")
    print("=" * 60)
    print(f"{'ID':<8} {'Genre Name'}")
    print("-" * 60)
    
    # Sort by name for display
    sorted_genres = sorted(genres, key=lambda x: x["name"])
    
    for genre in sorted_genres:
        print(f"{genre['id']:<8} {genre['name']}")
    
    print("-" * 60)
    print(f"Total: {len(genres)} genres")

def main():
    """Main function."""
    print("\nResident Advisor Genre Downloader")
    print("=" * 50)
    
    # Download the genres
    genres = download_genres()
    
    if not genres:
        print("Failed to download genres. Exiting.")
        return
    
    # Save to file
    save_genres(genres)
    
    # Display in console
    display_genres(genres)
    
    print("\nDone! You can now use the genres.json file in your applications.")

if __name__ == "__main__":
    main() 