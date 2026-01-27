# API Data Flow Explainer

This document explains exactly how the VT Gym Tracker app retrieves and processes gym occupancy data from the Virginia Tech RecSports API.

## API Endpoint

**URL:** `https://connect.recsports.vt.edu/FacilityOccupancy/GetFacilityData`

**Method:** `POST`

**Content-Type:** `application/x-www-form-urlencoded`

**Note:** This is not a REST API endpoint. It requires POST requests with form-encoded data.

## Request Format

Each request requires two parameters in the request body:

```
facilityId={UUID}&occupancyDisplayType={UUID}
```

### Facility IDs

The app tracks three facilities:

- **McComas Hall:** `da73849e-434d-415f-975a-4f9e799b9c39`
- **War Memorial Hall:** `55069633-b56e-43b7-a68a-64d79364988d`
- **Bouldering Wall:** `da838218-ae53-4c6f-b744-2213299033fc`

### Occupancy Display Type

A constant UUID required by the API: `00000000-0000-0000-0000-000000004490`

### Example Request

```http
POST /FacilityOccupancy/GetFacilityData HTTP/1.1
Host: connect.recsports.vt.edu
Content-Type: application/x-www-form-urlencoded

facilityId=da73849e-434d-415f-975a-4f9e799b9c39&occupancyDisplayType=00000000-0000-0000-0000-000000004490
```

## Response Format

The API returns **HTML**, not JSON. The HTML contains occupancy data in `data-*` attributes on HTML elements.

### Example Response Structure

```html
<canvas class="occupancy-chart" 
        data-occupancy="275" 
        data-remaining="325">
    <!-- Chart rendering code -->
</canvas>
```

The app extracts two values:
- `data-occupancy`: Current number of people in the facility
- `data-remaining`: Remaining capacity

## Data Flow

### 1. Request Initiation

**Entry Point:** `GymService.fetchAllGymOccupancy()`

The app fetches data for all three facilities concurrently using Swift's `async let`:

```swift
async let mc = fetchOne(facilityId: Constants.mcComasFacilityId)
async let wm = fetchOne(facilityId: Constants.warMemorialFacilityId)
async let bw = fetchOne(facilityId: Constants.boulderingWallFacilityId)
let (m, w, b) = await (mc, wm, bw)
```

This parallel fetching improves performance by requesting all facilities simultaneously rather than sequentially.

### 2. HTTP Request (`GymOccupancyFetcher.fetchOne`)

For each facility:

1. **Create URLRequest:**
   ```swift
   var req = URLRequest(url: Constants.facilityDataAPIURL)
   req.httpMethod = "POST"
   req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
   ```

2. **Build Request Body:**
   ```swift
   req.httpBody = "facilityId=\(facilityId)&occupancyDisplayType=\(Constants.occupancyDisplayType)".data(using: .utf8)
   ```

3. **Execute Request:**
   ```swift
   let (data, response) = try await urlSession.data(for: req)
   ```

4. **Validate Response:**
   - Check HTTP status code is 200-299
   - Verify data exists
   - Convert data to UTF-8 string

### 3. URLSession Configuration

The app uses a custom `URLSession` configuration:

```swift
let c = URLSessionConfiguration.default
c.timeoutIntervalForRequest = 30  // 30 second timeout
c.requestCachePolicy = .reloadIgnoringLocalCacheData  // Always fetch fresh data
```

**Why no caching?** Occupancy data changes frequently. Caching would show stale counts.

### 4. HTML Parsing (`OccupancyHTMLParser.parse`)

The HTML response is parsed using regex to extract the `data-occupancy` and `data-remaining` attributes:

**Pattern:** `data-occupancy="([0-9]+)"` and `data-remaining="([0-9]+)"`

**Process:**
1. Search HTML string for attribute pattern
2. Extract captured group (the numeric value)
3. Convert to `Int`
4. Return tuple: `(occupancy: Int, remaining: Int)?`

**Why regex instead of HTML parser?**
- No external dependencies required
- Simple attribute extraction doesn't need full HTML parsing
- Lightweight and fast

### 5. Data Processing (`GymService.storeAndNotify`)

After parsing:

1. **Update Published Properties:**
   ```swift
   self.mcComasOccupancy = mcComasData?.occupancy
   self.warMemorialOccupancy = warMemorialData?.occupancy
   self.boulderingWallOccupancy = boulderingWallData?.occupancy
   ```
   These `@Published` properties trigger SwiftUI view updates.

2. **Store in App Group UserDefaults:**
   ```swift
   let sharedDefaults = UserDefaults(suiteName: Constants.appGroupID)
   sharedDefaults.set(mc, forKey: "mcComasOccupancy")
   ```
   This allows widgets and the watch app to access the data.

3. **Notify Widgets:**
   ```swift
   WidgetCenter.shared.reloadAllTimelines()
   ```
   Widgets are immediately notified to refresh with new data.

## Refresh Schedule

### Foreground (App Active)

- **Interval:** 30 seconds
- **Trigger:** Timer fires when app is active (`UIApplication.didBecomeActiveNotification`)
- **Stops:** When app backgrounds (`UIApplication.willResignActiveNotification`)

**Why 30 seconds?** Balances data freshness with battery and network usage.

### Background/Widgets

- **Widget Timeline:** Requests refresh every 15 minutes (WidgetKit managed)
- **Widgets read from:** App Group UserDefaults (shared storage)

## Error Handling

### Network Failures

1. **All Facilities Fail:**
   - `isOnline` set to `false`
   - Retry scheduled after 60 seconds
   - Prevents immediate retry loop

2. **Partial Success:**
   - If any facility succeeds, `isOnline` remains `true`
   - Only successful facilities update their values
   - Failed facilities retain previous values

### Parsing Failures

- If HTML parsing fails, `fetchOne` returns `nil`
- The facility's occupancy remains unchanged
- No error is thrown; the app continues with available data

## Data Storage

### In-App (`GymService`)

- `@Published` properties for SwiftUI binding
- Updated on main thread (`@MainActor`)

### Shared Storage (App Group)

**App Group ID:** `group.VTGymApp.D8VXFBV8SJ`

**Keys:**
- `mcComasOccupancy` (Int)
- `warMemorialOccupancy` (Int)
- `boulderingWallOccupancy` (Int)
- `lastFetchDate` (Date)

**Used by:**
- Main iOS app
- Widget extensions
- Watch app

## Testing/Debugging Override

The app supports custom occupancy values for testing:

```swift
@Published var useCustomOccupancy: Bool = false
@Published var customMcComasOccupancy: Int? = 275
@Published var customWarMemorialOccupancy: Int? = 1025
@Published var customBoulderingWallOccupancy: Int? = 6
```

When enabled, these values override API data. Useful for:
- Testing UI without network
- Debugging display logic
- Demonstrating app functionality

## Complete Flow Diagram

```
ContentView.onAppear
    ↓
GymService.fetchAllGymOccupancy()
    ↓
GymOccupancyFetcher.fetchAll()
    ├─→ fetchOne(McComas) ──┐
    ├─→ fetchOne(War Memorial) ──┤ Concurrent HTTP POST requests
    └─→ fetchOne(Bouldering) ────┘
    ↓
    POST https://connect.recsports.vt.edu/FacilityOccupancy/GetFacilityData
    Body: facilityId={UUID}&occupancyDisplayType={UUID}
    ↓
    HTML Response with data-occupancy and data-remaining attributes
    ↓
OccupancyHTMLParser.parse(html)
    ↓
Regex extraction: data-occupancy="([0-9]+)" and data-remaining="([0-9]+)"
    ↓
Return (occupancy: Int, remaining: Int)?
    ↓
GymService.storeAndNotify()
    ├─→ Update @Published properties (SwiftUI updates)
    ├─→ Store in App Group UserDefaults (widgets/watch access)
    └─→ WidgetCenter.reloadAllTimelines() (notify widgets)
```

## Key Files

- **`GymOccupancyFetcher.swift`:** HTTP requests and concurrent fetching
- **`OccupancyHTMLParser.swift`:** HTML parsing via regex
- **`GymService.swift`:** Data management and refresh scheduling
- **`Constants.swift`:** API URLs, facility IDs, and configuration
