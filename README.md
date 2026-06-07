# Whence the Rave?

An iOS app for discovering electronic music events on a map. Browse listings by area and date, see venues near you, set reminders, and open full event details on [Resident Advisor](https://ra.co).

**Platform:** iOS 17.0+ (iPhone only)  
**Language:** Swift / SwiftUI  
**Repository:** [github.com/CastroSATT/Whence-the-Rave](https://github.com/CastroSATT/Whence-the-Rave)

---

## Features

### Map

- Interactive map with event pins (color reflects popularity / interest)
- Your location on the map with optional distance rings (km / miles)
- **LOC** — tap to center on your position at current zoom (haptic feedback on success)
- **FOL** — hold 3 seconds to follow your location and heading (follow mode)
- Pan and zoom freely; map does not snap back after you move it
- Tap a pin to open event details; map centers on selected events
- Compass / heading support on the map

### Event discovery

- Search by **area** (worldwide RA-supported cities/regions)
- Filter by date: today, tomorrow, next 7 / 14 / 30 days
- Sort by latest, popular, or A–Z
- **Find events near me** — auto-select nearest area from GPS
- **Nearby** list mode — events sorted by distance from you
- Sliding event list panel with swipe-to-open gestures
- Cached listings for offline / poor network use

### Event details

- Title, date, time, venue, address, artists
- Swipe between events in the detail sheet
- Open full listing on **ra.co**
- Venue link on Resident Advisor
- Local **reminders** (10 min to 1 week before the event)

### Notifications

- Schedule reminders per event
- Manage active reminders from the bell tab
- App badge shows pending event reminders

### Settings

- Distance unit (km / m / miles)
- Toggle distance circles and genre haptics
- Default search date and sort order
- Refresh area and genre databases
- Clear cached data
- Optional splash screen on launch

---

## Requirements

**Current release:** 1.0

- **iPhone only** — iOS 17.0 or later (iPad not supported)
- Location permission (recommended) for map centering and nearby events
- Notification permission (optional) for reminders
- Internet connection for live event data (cached data used when offline)

---

## Build and run

1. Clone the repository:
   ```bash
   git clone https://github.com/CastroSATT/Whence-the-Rave.git
   cd Whence-the-Rave
   ```
2. Open `Whence the Rave?.xcodeproj` in Xcode.
3. Select your development team under **Signing & Capabilities**.
4. Choose a physical device or simulator and press **Run** (⌘R).

> Haptic feedback (LOC / FOL) only works on a **physical device**, not the Simulator.

---

## Project structure

| Path | Purpose |
|------|---------|
| `Whence the Rave?/` | App source (Views, ViewModels, Services, Models) |
| `Whence the Rave?/Views/MapComponents/` | Map UI, navigation controller, tabs, event list |
| `Whence the Rave?/Services/` | RA API client, location, notifications, genres |
| `Whence the Rave?Tests/` | Unit tests |
| `Resources/` | Supporting resources (including Python tooling) |

Architecture: **SwiftUI + MVVM**, with `MapNavigationController` as the single owner of map camera and LOC/FOL mode.

---

## Data source

Event listings, venues, areas, and related metadata are loaded from **[Resident Advisor](https://ra.co)** (`ra.co`). This app is a third-party client and is **not** made by, sponsored by, or affiliated with Resident Advisor.

When you tap **VIEW ON RA** in the app, you are taken to the official event page on ra.co.

For the full legal disclaimer, see [DISCLAIMER.md](DISCLAIMER.md).

---

## Privacy

The app uses:

- **Location** — to show your position, find nearby areas, and calculate distance to venues (when-in-use only)
- **Notifications** — for event reminders you choose to set
- **Local storage** — to cache event and area data on your device

Location data is not sold or shared with third parties for advertising. Cached data can be cleared in Settings.

For the full privacy policy, see [PRIVACY.md](PRIVACY.md).

---

## Contributing and discussion

Issues and pull requests are welcome on this repository.

- **Bug reports:** open an [Issue](https://github.com/CastroSATT/Whence-the-Rave/issues) with steps to reproduce, iOS version, and device model
- **Feature ideas:** open an Issue describing the enhancement
- **Pull requests:** fork the repo, branch from `main`, and submit a PR with a clear description of the change

Please do not commit API keys, credentials, or personal data.

---

## License

All rights reserved. No license file is included; contact the repository owner if you wish to reuse this code.

---

## Disclaimer

**Whence the Rave?** is an independent application developed by [CastroSATT](https://github.com/CastroSATT). It is **not affiliated with, endorsed by, or officially connected to Resident Advisor** or any of its partners.

- Event names, venues, artists, dates, images, and other listing content are the property of their respective owners and are displayed for informational purposes.
- Data is obtained from publicly accessible sources on [ra.co](https://ra.co). Availability and accuracy depend on Resident Advisor's services; this app does not guarantee complete or up-to-date listings.
- Ticket purchases, cancellations, and event changes are handled solely on Resident Advisor or promoter platforms — always confirm details on the official RA page before making plans.
- This app is provided **"as is"** without warranty of any kind. The authors are not liable for missed events, incorrect information, or any loss arising from use of the app.
- "Resident Advisor" and "RA" are trademarks of their respective owners. This project uses those names only to describe the data source and link to official pages.

By using this app or this repository, you agree that you understand it is a fan-made discovery tool, not an official RA product.

See also: [DISCLAIMER.md](DISCLAIMER.md)

---

*Last updated: June 2026*
