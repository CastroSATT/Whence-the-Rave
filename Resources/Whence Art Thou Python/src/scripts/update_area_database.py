#!/usr/bin/env python3

"""
Update the countries_full.json file with the latest country and area codes from Resident Advisor.
This ensures the app has the most up-to-date location data for searches.
"""

import json
import requests
import pathlib
import sys
import os
from datetime import datetime

# Define paths for standalone version
SCRIPT_DIR = pathlib.Path(__file__).parent
ROOT_DIR = SCRIPT_DIR.parent.parent
DATA_DIR = ROOT_DIR / "src" / "data"
JSON_DIR = DATA_DIR / "json"
COUNTRIES_FILE = JSON_DIR / "countries_full.json"
BACKUP_DIR = JSON_DIR / "backups"

def get_countries_and_areas():
    """Fetch all countries and their areas from the RA GraphQL API."""
    url = "https://ra.co/graphql"
    headers = {
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "application/json, text/plain, */*",
        "Accept-Language": "en-US,en;q=0.9",
        "Origin": "https://ra.co",
        "Referer": "https://ra.co/events",
    }
    
    # The GraphQL query to fetch all countries and their areas
    query = """
    query GetCountriesAndAreas {
      countries {
        id
        name
        urlCode
        areas {
          id
          name
          urlName
          isCountry
          country {
            id
          }
        }
      }
    }
    """
    
    payload = {
        "query": query,
        "operationName": "GetCountriesAndAreas"
    }
    
    try:
        # Create a session to maintain cookies
        session = requests.Session()
        
        # First visit the main site to get any cookies needed
        print("Visiting main RA site to get cookies...")
        session.get("https://ra.co")
        
        # Make the API request
        print("Fetching countries and areas from RA GraphQL API...")
        response = session.post(url, json=payload, headers=headers)
        response.raise_for_status()
        
        # Parse and return the response
        data = response.json()
        if "data" in data and "countries" in data["data"]:
            print(f"Successfully fetched data for {len(data['data']['countries'])} countries.")
            return data
        else:
            print("Error: Unexpected response structure")
            print(f"Response: {data}")
            return None
    
    except requests.exceptions.RequestException as e:
        print(f"Error fetching countries and areas: {e}")
        return None

def update_countries_database():
    """Update the countries_full.json file with the latest data."""
    # Create directories if they don't exist
    JSON_DIR.mkdir(exist_ok=True, parents=True)
    BACKUP_DIR.mkdir(exist_ok=True)
    
    # Backup the existing file if it exists
    if COUNTRIES_FILE.exists():
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = BACKUP_DIR / f"countries_full_{timestamp}.json"
        
        print(f"Backing up existing file to {backup_file}")
        try:
            with open(COUNTRIES_FILE, "r") as src:
                with open(backup_file, "w") as dst:
                    dst.write(src.read())
            print("Backup created successfully.")
        except Exception as e:
            print(f"Error creating backup: {e}")
            if input("Continue without backup? (y/n): ").lower() != 'y':
                return False
    
    # Fetch the latest data
    data = get_countries_and_areas()
    if not data:
        print("Failed to fetch data. Update aborted.")
        return False
    
    # Save the new data
    try:
        with open(COUNTRIES_FILE, "w") as f:
            json.dump(data, f, indent=2)
        print(f"Successfully updated {COUNTRIES_FILE}")
        
        # Print some stats
        country_count = len(data["data"]["countries"])
        area_count = sum(len(country["areas"]) for country in data["data"]["countries"])
        print(f"Database now contains {country_count} countries and {area_count} areas.")
        return True
    
    except Exception as e:
        print(f"Error saving data: {e}")
        return False

def verify_database():
    """Verify the countries_full.json file has the expected structure."""
    try:
        if not COUNTRIES_FILE.exists():
            print(f"Error: {COUNTRIES_FILE} does not exist.")
            return False
            
        with open(COUNTRIES_FILE, "r") as f:
            data = json.load(f)
        
        if "data" not in data or "countries" not in data["data"]:
            print("Error: File has invalid structure (missing data.countries).")
            return False
            
        countries = data["data"]["countries"]
        if not countries or not isinstance(countries, list):
            print("Error: No countries found or invalid format.")
            return False
            
        # Check a few random countries to verify they have areas
        for country in countries[:5]:
            if "areas" not in country or not isinstance(country["areas"], list):
                print(f"Error: Country {country.get('name', 'Unknown')} missing areas array.")
                return False
        
        print(f"Database verification successful!")
        print(f"Found {len(countries)} countries.")
        
        # Print all countries and their areas
        print("\nCountry List with Area Counts:")
        print("-" * 60)
        print(f"{'Country Name':<30} {'Area Count':<10} {'Country ID':<10}")
        print("-" * 60)
        
        # Sort countries by name for easier reading
        sorted_countries = sorted(countries, key=lambda x: x["name"])
        
        for country in sorted_countries:
            name = country["name"]
            area_count = len(country["areas"])
            country_id = country["id"]
            print(f"{name[:29]:<30} {area_count:<10} {country_id:<10}")
        
        return True
        
    except Exception as e:
        print(f"Error verifying database: {e}")
        return False

def list_top_areas():
    """List top cities/areas from the database as a quick reference."""
    try:
        if not COUNTRIES_FILE.exists():
            print(f"Error: {COUNTRIES_FILE} does not exist.")
            return
            
        with open(COUNTRIES_FILE, "r") as f:
            data = json.load(f)
        
        countries = data["data"]["countries"]
        
        # Key areas we want to show
        key_areas = {
            "London": None,
            "Berlin": None,
            "New York City": None,
            "Paris": None,
            "Amsterdam": None,
            "Barcelona": None,
            "Tokyo": None
        }
        
        # Find the area IDs
        for country in countries:
            for area in country["areas"]:
                if area["name"] in key_areas:
                    key_areas[area["name"]] = (area["id"], country["name"])
        
        # Display the results
        print("\nQuick Reference - Key Areas:")
        print("-" * 50)
        print(f"{'Area Name':<15} {'Area ID':<8} {'Country':<20}")
        print("-" * 50)
        
        for area_name, info in key_areas.items():
            if info:
                area_id, country_name = info
                print(f"{area_name:<15} {area_id:<8} {country_name:<20}")
            else:
                print(f"{area_name:<15} {'Not found':<8} {'Unknown':<20}")
                
    except Exception as e:
        print(f"Error listing areas: {e}")

def main():
    """Main function to update the countries and areas database."""
    print("Resident Advisor Area Database Updater")
    print("=" * 50)
    
    action = input("Choose an action:\n1. Update database\n2. Verify database\n3. List key areas\n4. Update and verify\nChoice (1-4): ")
    
    if action == "1":
        update_countries_database()
    elif action == "2":
        verify_database()
    elif action == "3":
        list_top_areas()
    elif action == "4":
        if update_countries_database():
            verify_database()
            list_top_areas()
    else:
        print("Invalid choice. Exiting.")

if __name__ == "__main__":
    main() 