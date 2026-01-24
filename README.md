# VT Gym Tracker

A comprehensive iOS app for Virginia Tech students to track gym occupancy and manage their Hokie Passport. The app provides real-time occupancy data for both War Memorial Hall and McComas Hall gyms, along with upcoming events and a digital Hokie Passport feature.

## Features

### 🏋️ Real-Time Gym Occupancy
- **Live occupancy tracking** for War Memorial Hall and McComas Hall
- **Automatic data refresh** every 30 seconds when the app is active
- **Visual progress indicators** with color-coded occupancy levels:
  - Green: Low occupancy (0-50%)
  - Orange: Medium occupancy (50-75%)
  - Maroon: High occupancy (75-100%)

### 📱 Multi-Platform Support
- **iOS App**
- **iOS Widgets**: Home screen and lock screen widgets showing gym occupancy
- **Apple Watch App**: Quick gym status check on your wrist
- **Watch Complications**: Gym occupancy data directly on your watch face

### 🎫 Digital Hokie Passport
- **Barcode scanning** using device camera with Vision framework
- **Manual ID entry** as an alternative to scanning
- **Face ID/Touch ID protection** for secure access to stored passport
- **Local storage** - all data stays on your device
- **Copy to clipboard** functionality for easy sharing

### 📅 Events Integration
- **Upcoming events** from Virginia Tech Rec Sports RSS feed
- **Event details** including location, time, and hosting organization

### 🎨 Customization
- **Theme options**: Auto, Light, or Dark mode

## Technical Architecture

### Core Components
- **GymService**: Singleton service managing gym occupancy data fetching and caching
- **EventsViewModel**: Handles RSS feed parsing and event caching
- **NetworkMonitor**: Monitors connectivity status across the app

### Data Sources
- **Gym Occupancy**: Virginia Tech Rec Sports facility occupancy API
- **Events**: RSS feed from GobblerConnect
- **Local Storage**: UserDefaults and App Groups for data persistence

### Widget System
- **UnifiedGymTrackerProvider**: Shared timeline provider for all widgets
- **App Group**: `group.VTGymApp.D8VXFBV8SJ` for data sharing between app and widgets
- **Automatic refresh**: Widgets update roughly every 15 minutes (depending on usage) or when app data changes

## Installation

### Requirements
- iOS 17.0+ / watchOS 10.0+
- Xcode 16.0+
- Swift 5.9+

### Building from Source
1. Clone the repository:
   ```bash
   git clone https://github.com/Hann8n/VTGymTracker.git
   ```

2. Open `Gym Tracker.xcodeproj` in Xcode

3. Select your development team in project settings

4. Build and run on your device or simulator

### Project Structure
```
Gym Tracker (RC)/
├── Services/           # Core business logic
├── Events/            # Event management
├── BarCode Scanner/   # Passport scanning functionality
├── Assets.xcassets/   # App icons and images
└── ContentView.swift  # Main app interface

GymTrackerWidget/      # iOS Widget extension
GymTrackerWatch/       # Apple Watch app
GymTrackerComplications/ # Watch complications
```
 
### Key Technologies
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for data flow
- **WidgetKit**: iOS widget system
- **Vision**: Barcode detection
- **LocalAuthentication**: Biometric authentication
- **Regex-based HTML parser**: GetFacilityData HTML is parsed for `data-occupancy` and `data-remaining` (no SwiftSoup)

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT

*Virginia Tech is not associated with this project*
