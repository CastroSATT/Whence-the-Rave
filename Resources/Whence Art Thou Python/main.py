#!/usr/bin/env python3

"""
Whence Art Thou RA - Main Entry Point
A toolkit for finding and visualizing electronic music events from Resident Advisor.
"""

import sys
import os
import pathlib
import argparse
import importlib.util

# Add src directory to path
ROOT_DIR = pathlib.Path(__file__).parent
SRC_DIR = ROOT_DIR / "src"
sys.path.insert(0, str(ROOT_DIR))

def load_module(script_path):
    """Dynamically load a Python module from a file path."""
    spec = importlib.util.spec_from_file_location(script_path.stem, script_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

def find_events(args):
    """Find events using nearby_events.py script."""
    script_path = SRC_DIR / "scripts" / "nearby_events.py"
    if not script_path.exists():
        print(f"Error: {script_path} not found.")
        return
        
    # Pass the command line arguments to the script
    sys.argv = [str(script_path)] + args
    
    # Load and run the module
    module = load_module(script_path)
    module.main()

def generate_map(args):
    """Generate a map using map_events.py script."""
    script_path = SRC_DIR / "scripts" / "map_events.py"
    if not script_path.exists():
        print(f"Error: {script_path} not found.")
        return
        
    # Pass the command line arguments to the script
    sys.argv = [str(script_path)] + args
    
    # Load and run the module
    module = load_module(script_path)
    module.main()

def update_database(args):
    """Update the area database using update_area_database.py script."""
    script_path = SRC_DIR / "scripts" / "update_area_database.py"
    if not script_path.exists():
        print(f"Error: {script_path} not found.")
        return
        
    # Pass the command line arguments to the script
    sys.argv = [str(script_path)] + args
    
    # Load and run the module
    module = load_module(script_path)
    module.main()

def main():
    """Main entry point for the application."""
    parser = argparse.ArgumentParser(
        description="Resident Advisor Event Finder and Visualizer",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  Find events near your current location:
    python main.py find-events
    
  Find today's events in London:
    python main.py find-events --area "London" --today
    
  Find tomorrow's events in Berlin with map visualization:
    python main.py find-events --area "Berlin" --tomorrow --map
    
  Generate a map from the last search results:
    python main.py map
    
  Update the area database:
    python main.py update-database
"""
    )
    
    subparsers = parser.add_subparsers(dest="command", help="Command to run")
    
    # Find events command
    find_parser = subparsers.add_parser("find-events", help="Find events on Resident Advisor")
    find_parser.add_argument("--area", type=str, help="Area name to search for events")
    find_parser.add_argument("--area-id", type=str, help="Area ID to search for events")
    find_parser.add_argument("--nearby", action="store_true", help="Use your current location")
    find_parser.add_argument("--today", action="store_true", help="Show only today's events")
    find_parser.add_argument("--tomorrow", action="store_true", help="Show only tomorrow's events")
    find_parser.add_argument("--yesterday", action="store_true", help="Show only yesterday's events")
    find_parser.add_argument("--days", type=int, help="Number of days to look ahead (default: 7)")
    find_parser.add_argument("--page", type=int, default=1, help="Page number (default: 1)")
    find_parser.add_argument("--page-size", type=int, default=25, help="Results per page (default: 25, max: 50)")
    find_parser.add_argument("--sort", type=str, default="LATEST", 
                            choices=["LATEST", "POPULAR", "ALPHABETICAL"], 
                            help="Sort order (default: LATEST)")
    find_parser.add_argument("--no-urls", action="store_true", help="Hide URLs in the output")
    find_parser.add_argument("--map", action="store_true", help="Generate a map of event locations")
    
    # Map command
    map_parser = subparsers.add_parser("map", help="Generate a map from the last search results")
    
    # Update database command
    update_parser = subparsers.add_parser("update-database", help="Update the area database")
    
    args = parser.parse_args()
    
    # Handle commands
    if args.command == "find-events":
        # Convert namespace to list of arguments
        arg_list = []
        for arg, value in vars(args).items():
            if arg != "command" and value is not None:
                # Skip days argument if using today, tomorrow, or yesterday
                if arg == "days" and (args.today or args.tomorrow or args.yesterday):
                    continue
                if isinstance(value, bool):
                    if value:
                        arg_list.append(f"--{arg.replace('_', '-')}")
                else:
                    arg_list.append(f"--{arg.replace('_', '-')}")
                    arg_list.append(str(value))
        
        find_events(arg_list)
    elif args.command == "map":
        generate_map([])
    elif args.command == "update-database":
        update_database([])
    else:
        parser.print_help()

if __name__ == "__main__":
    main() 