# VT Gym Tracker

iOS app for tracking Virginia Tech gym occupancy and displaying campus events. Supports iOS, watchOS, and WidgetKit extensions.

## Architecture

### Core Services

**GymService** (`GymService.swift`)
- Singleton `@MainActor` class managing gym occupancy state
- Publishes `@Published` properties: `mcComasOccupancy`, `warMemorialOccupancy`, `boulderingWallOccupancy`
- Automatic refresh: 30-second interval when app is active (via `UIApplication.didBecomeActiveNotification`)
- Retry logic: 60-second delay if all fetches fail
- Uses `GymOccupancyFetcher` for data fetching

**GymOccupancyFetcher** (`GymOccupancyFetcher.swift`)
- Static enum performing HTTP requests
- Concurrent fetching: `async let` for parallel facility requests
- POST request to `https://connect.recsports.vt.edu/FacilityOccupancy/GetFacilityData`
- Request body: `facilityId={uuid}&occupancyDisplayType={uuid}` (URL-encoded)
- Response: HTML containing `data-occupancy` and `data-remaining` attributes
- Parsing: Delegates to `OccupancyHTMLParser` for regex extraction

**OccupancyHTMLParser** (`OccupancyHTMLParser.swift`)
- Regex-based HTML parsing (no external dependencies)
- Pattern: `data-occupancy="([0-9]+)"` and `data-remaining="([0-9]+)"`
- Extracts occupancy and remaining capacity integers from HTML response

**EventsViewModel** (`EventsViewModel.swift`)
- Fetches RSS feed from `https://gobblerconnect.vt.edu/organization/www_recsports_vt_edu/events.rss`
- XML parsing via `XMLParser` delegate pattern (`RSSParser` class)
- Caching: JSON file in app caches directory (`cachedEvents.json`)
- Filters: Only caches events where `endDate > Date()`
- Network monitoring: Observes `NetworkMonitor.isConnected` via Combine

### Data Flow

**Gym Occupancy:**
1. `ContentView.onAppear` → `fetchGymOccupancyData()`
2. `GymService.fetchAllGymOccupancy()` → `GymOccupancyFetcher.fetchAll()`
3. Concurrent POST requests for three facilities (McComas, War Memorial, Bouldering Wall)
4. HTML response parsed via regex for `data-occupancy`/`data-remaining`
5. Results stored in `GymService` `@Published` properties
6. UI updates via SwiftUI `@ObservedObject` binding

**Events:**
1. `ContentView.onAppear` → `eventsViewModel.fetchEvents()`
2. RSS feed fetched via `URLSession.dataTask`
3. XML parsed via `RSSParser` (NSXMLParser delegate)
4. Events filtered by `endDate > Date()`
5. Cached to JSON file, loaded on init if available

**Widgets:**
1. `UnifiedGymTrackerProvider.getTimeline()` called by WidgetKit
2. `GymOccupancyFetcher.fetchForWidget()` fetches occupancy (no remaining capacity)
3. Results stored in App Group UserDefaults (`group.VTGymApp.D8VXFBV8SJ`)
4. Fallback to cached values if fetch fails
5. Timeline policy: `.after(15 minutes)`

### Facility IDs & Capacities

```swift
mcComasFacilityId: "da73849e-434d-415f-975a-4f9e799b9c39"
warMemorialFacilityId: "55069633-b56e-43b7-a68a-64d79364988d"
boulderingWallFacilityId: "da838218-ae53-4c6f-b744-2213299033fc"

mcComasMaxCapacity: 600
warMemorialMaxCapacity: 1200
boulderingWallMaxCapacity: 8
```

### Barcode System

**Storage:**
- `@AppStorage("gymBarcode")` stores Codabar string (e.g., "A12345B")
- Optional `@AppStorage("faceIDEnabled")` for biometric protection

**Scanning:**
- `BarcodeScannerView` uses `CodeScannerView` (third-party library)
- Scans Codabar format (`codeTypes: [.codabar]`)
- Validation: Ensures start/end characters are A/B/C/D
- Auto-prefix/suffix if missing: defaults to "A" prefix, "B" suffix

**Generation:**
- `BarcodeGenerator` uses `CDCodabarView` (third-party library)
- Generates `UIImage` from Codabar string
- Displayed in `BarcodeDisplayOverlayView` with brightness boost via `BrightnessManager`

**Authentication:**
- `LocalAuthentication` framework for Face ID/Touch ID
- `LAContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)`
- Triggered before displaying stored barcode if `faceIDEnabled == true`

### App Group & Shared Storage

- App Group ID: `group.VTGymApp.D8VXFBV8SJ`
- Shared UserDefaults keys:
  - `mcComasOccupancy` (Int)
  - `warMemorialOccupancy` (Int)
  - `boulderingWallOccupancy` (Int)
  - `lastFetchDate` (Date)
- Used by: Main app, Widget extension, Watch app

### UI Components

**ContentView:**
- `NavigationStack` with grouped `List`
- Sections: War Memorial, McComas, Bouldering Wall, Events
- `OccupancyCard` displays occupancy with segmented progress bar
- Color thresholds: Green (0-50%), Orange (50-75%), Maroon (75-100%)

**OccupancyCard:**
- Segmented progress visualization
- Displays occupancy count and remaining capacity
- Network status indicator

**EventCard:**
- Displays event title, location, time, hosting organization
- Date range: Today through 14 days ahead

### Widget System

**UnifiedGymTrackerProvider:**
- Single timeline provider for all widget sizes
- `getTimeline()` fetches occupancy data
- Stores in App Group UserDefaults
- Timeline refresh: 15-minute intervals
- Widget types: Home screen widgets, Lock screen widgets

### Watch App

- `WatchFacilitiesView` displays gym occupancy
- `WatchGymCardView` shows individual facility status
- `WatchSegmentedProgressBar` visual indicator
- Shares data via App Group UserDefaults

### Dependencies

- **CodeScanner**: Barcode scanning (`CodeScannerView`)
- **CDCodabarView**: Codabar barcode generation
- **SwiftUI**: UI framework
- **Combine**: Reactive data flow
- **WidgetKit**: Widget system
- **LocalAuthentication**: Biometric authentication
- **AVFoundation**: Camera access for barcode scanning

### Build Requirements

- iOS 17.0+
- watchOS 10.0+
- Xcode 16.0+
- Swift 5.9+

### Project Structure

```
Gym Tracker (RC)/
├── Services/
│   ├── GymService.swift              # Main occupancy service
│   ├── GymOccupancyFetcher.swift     # HTTP fetching
│   ├── OccupancyHTMLParser.swift     # Regex HTML parsing
│   ├── Constants.swift                # Facility IDs, capacities, URLs
│   └── UnifiedGymTrackerProvider.swift # Widget timeline provider
├── Events/
│   ├── EventsViewModel.swift         # RSS fetching & caching
│   └── Event.swift                    # Event model
├── BarCode Scanner/
│   ├── BarcodeScannerView.swift      # Camera scanning UI
│   ├── BarcodeGenerator.swift        # Codabar image generation
│   ├── BarcodeDisplayView.swift      # Display overlay
│   ├── ManualIDInputView.swift       # Manual entry UI
│   └── BrightnessManager.swift       # Screen brightness control
├── ContentView.swift                 # Main app view
└── OccupancyCard.swift               # Occupancy display component

GymTrackerWidget/                      # Widget extension
GymTrackerWatch Watch App/             # Watch app
GymTrackerComplications/               # Watch complications
```

### Privacy Policy

Hosted via GitHub Pages at `/docs/privacy-policy.html`. Configure in repo Settings → Pages: deploy from `main` branch, `/docs` folder.

### License

This project is licensed under the **MIT License**. See the `LICENSE` file for full text.

---

*Virginia Tech is not associated with this project*
