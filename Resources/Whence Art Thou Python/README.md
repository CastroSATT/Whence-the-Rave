# Whence Art Thou RA

A standalone toolkit for finding and visualizing electronic music events from Resident Advisor (RA.co) using their GraphQL API. The system auto-detects your location or lets you search for events worldwide with powerful filtering options and interactive map visualization.

## Installation

1. Clone or download this repository
2. Create and activate a virtual environment:
   ```
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```
3. Install dependencies:
   ```
   pip install -r requirements.txt
   ```
4. Update the area database (required for first use):
   ```
   python main.py update-database
   ```

## Usage

### Finding Events

```bash
# Find events near your current location (auto-detected through IP)
python main.py find-events

# Find today's events in London
python main.py find-events --area "London" --today

# Find tomorrow's events in Berlin with map visualization
python main.py find-events --area "Berlin" --tomorrow --map

# Find upcoming events in a specific area and sort by popularity
python main.py find-events --area "Amsterdam" --days 14 --sort POPULAR
```

### Command Line Options:

| Option | Description |
|--------|-------------|
| `--area NAME` | Area name to search (e.g., "London", "Berlin") |
| `--area-id ID` | Area ID to search (e.g., 13 for London, 34 for Berlin) |
| `--nearby` | Use your current location (default if no area specified) |
| `--today` | Show only today's events |
| `--tomorrow` | Show only tomorrow's events |
| `--yesterday` | Show only yesterday's events |
| `--days N` | Number of days to look ahead (default: 7) |
| `--page N` | Page number (default: 1) |
| `--page-size N` | Results per page (default: 25, max: 50) |
| `--sort MODE` | Sort order: LATEST, POPULAR, ALPHABETICAL |
| `--no-urls` | Hide URLs in the output |
| `--map` | Automatically generate and open a map of events |

### Map Visualization

After running a search for events, you can visualize them on an interactive map:

```bash
# Generate a map from the last search results
python main.py map
```

The map shows:
- Events color-coded by popularity:
  - Red: Very popular (500+ interested people)
  - Orange: Popular (100-500 interested people)
  - Blue: Less popular (<100 interested people)
- Your current location (green marker)
- Distance circles at 1km, 3km, and 5km from your location
- Interactive tooltips showing event name, date, time and venue
- Detailed popups with artist lineups and links to event pages

### Updating Area Database

The application relies on a database of countries and areas from Resident Advisor. This database needs to be updated periodically to ensure you have access to the latest locations.

```bash
# Run the area database updater
python main.py update-database
```

The updater provides several options:
1. **Update database** - Fetches the latest countries and areas from RA
2. **Verify database** - Checks if your current database is valid
3. **List key areas** - Shows IDs for major cities like London, Berlin, NYC
4. **Update and verify** - Performs all the above actions

## Project Structure

```
.
├── main.py                        # Main entry point
├── README.md                      # Project documentation
├── requirements.txt               # Python dependencies
├── debug_response.json            # Latest API response for debugging/mapping
├── ra_events_map.html             # Generated map output
└── src/                           # Source code
    ├── api/                       # API client modules
    │   └── client.py              # GraphQL API client implementation
    ├── data/                      # Data storage
    │   ├── csv/                   # CSV data files
    │   └── json/                  # JSON data files including area/country data
    │       ├── countries_full.json # Cached country and area information
    │       └── backups/           # Backups of area database files
    └── scripts/                   # Executable scripts
        ├── nearby_events.py       # Main event finder script with location detection
        ├── map_events.py          # Map visualization generator
        └── update_area_database.py # Tool to update country/area database
```

## License

This project is for educational purposes only. The Resident Advisor API is owned by Resident Advisor Ltd. This project is not affiliated with Resident Advisor. 