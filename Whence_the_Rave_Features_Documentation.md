# Whence the Rave? - iOS App Features Documentation

## Overview

**Whence the Rave?** is a sophisticated iOS application designed to help electronic music enthusiasts discover and track rave events worldwide. The app integrates with Resident Advisor's GraphQL API to provide real-time event data with advanced mapping, location services, and notification capabilities.

**App Category:** Navigation  
**Platform:** iOS 18.0+  
**UI Style:** Dark theme with neo-punk aesthetic  
**Architecture:** SwiftUI with MVVM pattern  

---

## 🗺️ Core Map Features

### Interactive Event Map
- **Real-time Event Visualization**: Events displayed as color-coded pins on an interactive map
- **Event Color Coding by Popularity**:
  - High popularity (500+ interested): Prominent markers
  - Medium popularity (100-500 interested): Standard markers  
  - Low popularity (<100 interested): Subtle markers
- **User Location Tracking**: Shows your current position with heading indicator
- **Distance Circles**: Configurable distance rings (1km, 3km, 5km) around user location
- **Venue Mapping**: Precise venue locations with address information

### Map Controls & Navigation
- **Zoom Controls**: Automatic zoom to fit events or user-defined radius
- **Compass Integration**: Shows device heading and orientation
- **Region Management**: Intelligent map region updates based on event locations
- **Touch Interactions**: Tap events to view details, drag to explore areas

### Location Services
- **GPS Integration**: Real-time location tracking with CoreLocation
- **Heading Updates**: Compass and device orientation tracking
- **Location Permissions**: Proper handling of location authorization states
- **Automatic Area Detection**: Finds nearest RA area based on user location
- **Distance Calculations**: Calculates distances to venues in multiple units

---

## 🎵 Event Discovery & Management

### Event Search & Filtering
- **Date Range Filtering**:
  - Today only
  - Tomorrow only  
  - Next 7 days
  - Next 14 days
  - Next 30 days
- **Area-Based Search**: Search events by specific cities/regions worldwide
- **Sorting Options**:
  - Latest (by date)
  - Popular (by interested count)
  - Alphabetical (A-Z)

### Event Data & Details
- **Comprehensive Event Information**:
  - Event title and description
  - Date, start time, and end time
  - Venue name and address
  - Artist lineups with links
  - Event flyers and images
  - Ticket information and availability
  - Interest count (popularity metric)
- **Genre Classification**: Events categorized by music genres
- **Promoter Information**: Details about event organizers
- **RA Integration**: Direct links to full event pages on Resident Advisor

### Event List Panel
- **Sliding Side Panel**: Swipeable event list with drag gestures
- **Event Previews**: Quick event cards with essential information
- **Navigation Between Events**: Horizontal swiping between event details
- **Real-time Updates**: Live event data synchronization

---

## 🔔 Notification System

### Event Reminders
- **Flexible Notification Timing**:
  - 10 minutes before event
  - 30 minutes before event
  - 1 hour before event
  - 3 hours before event
  - 1 day before event
  - 3 days before event
  - 1 week before event
- **Smart Scheduling**: Automatic calculation of notification timing based on event dates
- **Permission Management**: Proper handling of notification permissions

### Notification Management
- **Active Notifications View**: Dedicated interface to manage all scheduled notifications
- **Notification History**: Track and manage previously set reminders
- **Badge Count Updates**: App icon badge reflects pending notifications
- **Cancellation Options**: Easy removal of unwanted notifications

---

## ⚙️ Settings & Configuration

### Map Settings
- **Distance Unit Selection**: Choose between kilometers, meters, or miles
- **Distance Circle Toggle**: Show/hide distance rings on map
- **Heading Indicator**: Enable/disable compass heading display
- **Splash Screen Control**: Toggle splash screen on app launch

### Data Management
- **Cache Management**: Clear cached event and area data
- **Database Updates**: 
  - Refresh country/area database from RA API
  - Update genre database
  - Force refresh options for latest data
- **Offline Support**: Cached data available when network is unavailable

### Search Preferences
- **Default Area Selection**: Set preferred search location
- **Auto-refresh Settings**: Configure automatic data refresh on startup
- **Sort Preference**: Default sorting option for event lists

### Developer Features
- **Developer Mode**: Hidden developer options (activated by tapping version multiple times)
- **Verbose Logging**: Enhanced debug logging for troubleshooting
- **API Request Monitoring**: Track API calls and responses
- **Debug Data Export**: Save API responses for analysis

---

## 🌍 Location & Area Management

### Global Coverage
- **Worldwide Event Search**: Access to RA events globally
- **Country/Area Database**: Comprehensive database of RA-supported locations
- **Area Picker Interface**: Searchable list of all available areas
- **Automatic Location Detection**: Find nearest area based on GPS coordinates

### Location Intelligence
- **Smart Area Selection**: Auto-select nearest area when location is available
- **Distance Calculations**: Real-time distance calculations to venues
- **Regional Optimization**: Map regions optimized for selected areas
- **Location Caching**: Efficient location data storage and retrieval

---

## 🎨 User Interface & Experience

### Neo-Punk Design Theme
- **Dark Mode Interface**: Consistent dark theme throughout the app
- **Neon Accent Colors**: Pink and green highlights for interactive elements
- **Monospaced Typography**: Technical, cyberpunk-inspired font choices
- **Gradient Elements**: Subtle gradients for visual depth

### Navigation & Flow
- **Tab-Based Navigation**: Right-side navigation tabs for core functions
- **Modal Presentations**: Settings, notifications, and detail views as modals
- **Gesture Support**: Swipe gestures for panel control and event navigation
- **Smooth Animations**: Fluid transitions between views and states

### Accessibility
- **VoiceOver Support**: Screen reader compatibility
- **Dynamic Type**: Respects system font size preferences
- **High Contrast**: Readable color combinations
- **Touch Targets**: Appropriately sized interactive elements

---

## 🔧 Technical Architecture

### API Integration
- **GraphQL Client**: Custom RA.co GraphQL API client
- **Real-time Data**: Live event data fetching with pagination
- **Error Handling**: Comprehensive error management and user feedback
- **Rate Limiting**: Respectful API usage with proper delays
- **Response Caching**: Intelligent caching for offline functionality

### Data Management
- **SwiftData Integration**: Modern data persistence layer
- **JSON Caching**: Event and area data cached locally
- **Background Sync**: Data updates without blocking UI
- **Cache Invalidation**: Smart cache refresh strategies

### Performance Optimization
- **Lazy Loading**: Events loaded on-demand with pagination
- **Memory Management**: Efficient handling of large event datasets
- **Background Processing**: Network requests on background queues
- **Image Caching**: Event flyer and image caching system

### Network & Connectivity
- **Network Monitoring**: Real-time network status tracking
- **Offline Mode**: Graceful degradation when network unavailable
- **Retry Logic**: Automatic retry for failed network requests
- **Connection Recovery**: Smart reconnection handling

---

## 📱 Platform Integration

### iOS Features
- **CoreLocation**: GPS and heading services
- **MapKit**: Native map rendering and annotations
- **UserNotifications**: Local notification scheduling
- **Background App Refresh**: Data updates in background
- **Handoff Support**: Continuity between devices (if implemented)

### Device Compatibility
- **iPhone Optimized**: Portrait orientation, iPhone-first design
- **iPad Support**: Responsive layout for larger screens
- **iOS 18.0+**: Modern iOS feature utilization
- **Hardware Requirements**: GPS, gyroscope, magnetometer required

---

## 🚀 Advanced Features

### Intelligent Event Discovery
- **Popularity Algorithms**: Events ranked by community interest
- **Geographic Relevance**: Location-aware event recommendations
- **Date Intelligence**: Smart date range suggestions
- **Venue Recognition**: Automatic venue categorization and mapping

### Data Analytics
- **Usage Tracking**: Anonymous usage patterns (if implemented)
- **Performance Metrics**: App performance monitoring
- **Error Reporting**: Crash and error analytics
- **User Preferences**: Learning from user behavior patterns

### Future-Ready Architecture
- **Modular Design**: Easily extensible codebase
- **Protocol-Oriented**: Flexible, testable architecture
- **Combine Framework**: Reactive programming patterns
- **SwiftUI**: Modern, declarative UI framework

---

## 🔒 Privacy & Security

### Data Protection
- **Location Privacy**: Location data used only for event discovery
- **No Personal Data Storage**: Minimal personal information collection
- **Secure API Communication**: HTTPS-only API communication
- **Local Data Encryption**: Sensitive data encrypted on device

### User Control
- **Permission Management**: Clear permission requests and explanations
- **Data Deletion**: Users can clear all cached data
- **Opt-out Options**: Granular control over app features
- **Transparency**: Clear data usage explanations

---

## 📋 Summary

**Whence the Rave?** is a comprehensive electronic music event discovery platform that combines:

- **Real-time event data** from Resident Advisor's extensive database
- **Advanced mapping capabilities** with location intelligence
- **Flexible notification system** for event reminders  
- **Intuitive user interface** with neo-punk aesthetic
- **Robust offline functionality** with intelligent caching
- **Global coverage** with local optimization
- **Privacy-focused design** with minimal data collection

The app serves as a complete solution for electronic music enthusiasts to discover, track, and navigate to events worldwide, with a focus on user experience, performance, and reliability.

---

*This documentation covers the current feature set as of the latest version. The app is designed with extensibility in mind, allowing for future enhancements and additional functionality.*


