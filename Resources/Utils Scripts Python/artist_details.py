#!/usr/bin/env python3
"""
Standalone script to fetch and display Resident Advisor artist details by slug or ID.
"""
import sys
import argparse
import requests

API_URL = "https://ra.co/graphql"
HEADERS = {
    "Content-Type": "application/json",
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "application/json, text/plain, */*",
    "Accept-Language": "en-US,en;q=0.9",
    "Origin": "https://ra.co",
    "Referer": "https://ra.co/dj/erroneous",
}

def fetch_artist_slug_by_id(artist_id):
    query = '''
    query GetArtist($id: ID!) {
      artist(id: $id) {
        id
        name
        urlSafeName
      }
    }
    '''
    variables = {"id": artist_id}
    payload = {"query": query, "variables": variables, "operationName": "GetArtist"}
    resp = requests.post(API_URL, json=payload, headers=HEADERS)
    resp.raise_for_status()
    data = resp.json()
    if data.get("data") and data["data"].get("artist"):
        return data["data"]["artist"].get("urlSafeName")
    return None

def fetch_artist_details_by_slug(slug):
    query = '''
    query GET_ARTIST_BY_SLUG($slug: String!) {
      artist(slug: $slug) {
        id
        name
        followerCount
        firstName
        lastName
        aliases
        isFollowing
        coverImage
        contentUrl
        facebook
        soundcloud
        instagram
        twitter
        bandcamp
        discogs
        website
        urlSafeName
        pronouns
        country { id name urlCode }
        residentCountry { id name urlCode }
        news(limit: 1) { id }
        reviews(limit: 1, type: ALLMUSIC) { id }
        ...biographyFields
      }
    }
    fragment biographyFields on Artist {
      id
      name
      contentUrl
      image
      biography {
        id
        blurb
        content
        discography
      }
    }
    '''
    variables = {"slug": slug}
    payload = {"query": query, "variables": variables, "operationName": "GET_ARTIST_BY_SLUG"}
    resp = requests.post(API_URL, json=payload, headers=HEADERS)
    resp.raise_for_status()
    data = resp.json()
    if data.get("data") and data["data"].get("artist"):
        return data["data"]["artist"]
    return None

def display_artist_details(artist):
    if not artist:
        print("No artist data to display")
        return
    print("\n" + "=" * 80)
    print(f"ARTIST: {artist.get('name', 'No name')}")
    print("=" * 80)
    print(f"ID: {artist.get('id')}")
    print(f"URL: https://ra.co{artist.get('contentUrl')}")
    print(f"Follower Count: {artist.get('followerCount')}")
    print(f"First Name: {artist.get('firstName')}")
    print(f"Last Name: {artist.get('lastName')}")
    print(f"Aliases: {artist.get('aliases')}")
    print(f"Is Following: {artist.get('isFollowing')}")
    print(f"Cover Image: {artist.get('coverImage')}")
    print(f"Profile Image: {artist.get('image')}")
    print(f"URL Safe Name: {artist.get('urlSafeName')}")
    print(f"Pronouns: {artist.get('pronouns')}")
    print(f"Country: {artist.get('country', {}).get('name', '')}")
    print(f"Resident Country: {artist.get('residentCountry', {}).get('name', '')}")
    print(f"Facebook: {artist.get('facebook')}")
    print(f"Soundcloud: {artist.get('soundcloud')}")
    print(f"Instagram: {artist.get('instagram')}")
    print(f"Twitter: {artist.get('twitter')}")
    print(f"Bandcamp: {artist.get('bandcamp')}")
    print(f"Discogs: {artist.get('discogs')}")
    print(f"Website: {artist.get('website')}")
    news = artist.get('news', [])
    if news:
        print("News IDs: " + ", ".join(str(n.get('id')) for n in news))
    reviews = artist.get('reviews', [])
    if reviews:
        print("Review IDs: " + ", ".join(str(r.get('id')) for r in reviews))
    bio = artist.get('biography', {})
    if bio:
        print("\nBIOGRAPHY:")
        print(f"  ID: {bio.get('id')}")
        if bio.get('blurb'):
            print(f"  Blurb: {bio.get('blurb')}")
        if bio.get('content'):
            print(f"  Content: {bio.get('content')[:300]}{'...' if len(bio.get('content')) > 300 else ''}")
        if bio.get('discography'):
            print(f"  Discography: {bio.get('discography')}")
    print("=" * 80)

def main():
    parser = argparse.ArgumentParser(description="Fetch Resident Advisor artist details by slug or ID.")
    parser.add_argument("artist", help="Artist slug (name) or ID")
    args = parser.parse_args()
    artist_arg = args.artist
    # Determine if input is ID (all digits) or slug
    if artist_arg.isdigit():
        slug = fetch_artist_slug_by_id(artist_arg)
        if not slug:
            print(f"Could not find slug for artist ID {artist_arg}")
            sys.exit(1)
    else:
        slug = artist_arg
    artist = fetch_artist_details_by_slug(slug)
    if not artist:
        print(f"Could not find artist details for slug '{slug}'")
        sys.exit(1)
    display_artist_details(artist)

if __name__ == "__main__":
    main() 