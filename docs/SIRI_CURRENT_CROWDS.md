# Current crowds in Siri and Shortcuts

The crowds action, **Check Current Crowds**, is exposed, with a **Facility** parameter:
McComas Hall, War Memorial Hall, Bouldering Wall, or All Facilities (the default).
It completes in the background and returns an array of typed `FacilityCrowdsEntity`
results plus a short spoken response. It does not open a screen or require the
app's UI singleton to initialize.

Example phrases use the installed app name, **Gym Tracker**:

- “Check current crowds with Gym Tracker.”
- “Compare gyms with Gym Tracker.”
- “Check crowds at McComas Hall with Gym Tracker.”
- “How busy is War Memorial Hall in Gym Tracker?”

The fixed enum includes aliases such as McComas, War, WMH, WMH Service Desk,
Bouldering, and Climbing Wall. Shortcuts presents the four explicit choices.
Siri handles unresolved/ambiguous parameters using that choice set; there is no
free-text guessing or app-side language model. Speech recognition and actual
Siri disambiguation must be checked on a device.

## Result contract

Each individual facility has typed properties for facility enum, source ID,
name, climbing-facility flag, optional count, known capacity, optional calculated
fullness percent, live/cached/unavailable status, optional fetched-at date,
checked-at date, optional last successful fetch date, optional cache age in
seconds, availability detail, and source URL/name/limitation.

`sourceMeasuredAt` is absent (`nil`): RecSports does not publish a measurement
timestamp in the response. Fetch time and HTTP Date must never be presented as
measurement time. “Live” means a valid response was retrieved during this
invocation, not independently measured at that instant. The source warns that
counts depend on swipe-in and swipe-out accuracy.

Unknown counts, percentages and fetch dates remain absent, never zero. Zero
is a valid available reading. The result is transient so Shortcuts can pass the
retrieved values to later actions without a persistent entity query silently
fetching a different count.

For All Facilities the dialog reports all three records. It compares the two
gyms using exact calculated percentages, and ranks them only when both responses
are live. A climbing-wall count is reported separately. There are no forecasts,
historical records, inferred opening hours, or Foundation Models features.

## Shared fetching and freshness

`GymOccupancyFetcher.fetchSnapshots` owns the HTTP/validation path. The app,
widgets and independent Watch app reuse it. Requests remain concurrent across
three small facility POSTs, with a 12-second request timeout and 15-second total
resource timeout. HTTP response caching is disabled. Results preserve facility
order and individual failures.

The HTML parser accepts consistent desktop/mobile canvas duplicates and requires
nonnegative integers, matching requested facility identity, count/remaining
within configured capacity, and count + remaining = capacity. Missing, malformed,
conflicting, overflow and wrong-facility responses are unavailable.

Siri attempts a live fetch first. On failure it may reuse a verified **existing
app-group current value** fetched within 90 seconds, matching the existing
widget freshness window. It discloses the original fetch time and actual age;
age is rechecked after the request. Older/future-dated readings are unavailable.
Siri has no 15-minute or 12-hour stale fallback. The app retains main’s existing
12-hour launch display and 15-minute per-facility fallback; these cannot establish
Siri freshness. The old global `lastFetchDate`
cannot establish a facility's freshness, so older installations start without
eligible Siri fallback until a real successful fetch creates the companion
per-facility success date. A failure removes the current count and preserves the
last-success date. There is no occupancy history or new HTTP response cache.

App/widget DEBUG screenshot mocks remain enabled as before. Their writes clear
verified success dates so Siri never reuses mocks as live data. The Siri path
always requests real data, including DEBUG. Deterministic tests inject a
URLSession with a fixture URLProtocol instead of disabling these protections.

On 2026-10-08 the public RecSports FacilityOccupancy page confirmed capacities
600 (McComas), 1200 (War Memorial / source title “WMH Service Desk”), and 8
(Bouldering Wall). McComas's previous source ID returned HTTP 500; its current
published ID works and is updated centrally in Constants.swift.

## Verification commands

Host contract suite (one compiler job, no simulator):

```sh
swift test --jobs 1 --scratch-path /tmp/vtgym-crowds-tests
```

Separate real-network/no-UI intent invocation:

```sh
VTGYM_LIVE_CHECK=1 swift test --jobs 1 --scratch-path /tmp/vtgym-crowds-tests \
  --filter CrowdsTests/testLiveIntentWithoutUI
```

The live test is intentionally skipped in the deterministic suite. Do not weaken
its fixtures or turn off screenshot mocks globally to make verification pass.
Build the main app plus embedded widget extension with the Release configuration;
build the independent Watch scheme separately. iOS 17 and watchOS 10 minimums
remain unchanged. Only App Intents APIs available at these minimums are used.

Final device checks: confirm the action appears in Shortcuts after installing/
launching the app, speak the example phrases and aliases, run from Siri with the
app backgrounded, inspect returned properties in a downstream Shortcuts action,
and verify spoken handling of partial/unavailable data. Simulator metadata and
host invocation cannot verify real Siri speech recognition or locked-device
behavior.

Apple references:

- [Creating your first app intent](https://developer.apple.com/documentation/appintents/creating-your-first-app-intent)
- [AppEntity](https://developer.apple.com/documentation/appintents/appentity)
- [AppShortcutsProvider](https://developer.apple.com/documentation/appintents/appshortcutsprovider)
- [TransientAppEntity](https://developer.apple.com/documentation/appintents/transientappentity)

After an app build, validate Xcode's generated system-facing metadata:

```sh
python3 scripts/verify_crowds_metadata.py '/path/to/Gym Tracker RC.app'
```

The combined shortcut provider also exposes [recreation event actions](SIRI_EVENTS.md).
