# Current crowds in Siri and Shortcuts

The crowds action, **Check Current Crowds**, is exposed, with a **Facility** parameter:
Both Gyms (the default), McComas Hall, War Memorial Hall, Bouldering Wall, or All Facilities.
The default covers only McComas and War Memorial, the two full-service gyms.
Bouldering is returned only when explicitly selected or asking for All Facilities,
and is introduced separately in that response.
It explicitly supports background execution on iOS 26+ and keeps the non-opening
compatibility flag for iOS 17–25. It completes in the background and returns an array of typed `FacilityCrowdsEntity`
results plus a short spoken response. It does not open a screen or require the
app's UI singleton to initialize.

Example phrases use **Gym Tracker**, or its Siri nickname **VT Gyms**:

- “What are the crowds like at McComas Hall using Gym Tracker?”
- “What are the crowds like at VT Gyms?”
- “Which gym should I go to at VT Gyms?”
- “Check which gym I should go to with Gym Tracker.”
- “Check current crowds with Gym Tracker.”
- “Check the McComas crowds with Gym Tracker.”
- “Compare gyms with Gym Tracker.”
- “Check crowds at McComas Hall with Gym Tracker.”
- “How busy is War Memorial Hall in Gym Tracker?”
- “What are the crowds at McComas gym with Gym Tracker?”
- “How crowded is McComas gym with Gym Tracker?”
- “What is the occupancy at McComas gym with Gym Tracker?”

The fixed enum includes aliases such as McComas, War, WMH, WMH Service Desk,
Bouldering, and Climbing Wall. Shortcuts presents five explicit choices, including Both Gyms and All Facilities.
Siri handles unresolved/ambiguous parameters using that choice set; there is no
free-text guessing or app-side language model. Speech recognition and actual
Siri disambiguation must be checked on a device.

## When Siri does not find the action

Automatic App Shortcut phrases require the app name or a declared app-name synonym.
**VT Gyms** is a supported Siri nickname, so “at VT Gyms” satisfies the app-name
placeholder without saying “with Gym Tracker”. The app display name stays **Gym Tracker**. A bare
question like “What are the crowds at McComas gym?” is not a registered global
Siri command. In Settings → Siri & Shortcuts, the Shortcuts link opens the app's
actions. Run **Check Current Crowds** with Facility **McComas Hall** there first.
If it returns a result, fetching and intent execution work; Siri routing remains
the separate check. Include “with Gym Tracker” in the spoken question.

For that exact question without the app name, create a personal shortcut with
**Check Current Crowds**, select **McComas Hall**, and rename the shortcut
**What are the crowds at McComas gym**. Siri can run a personal shortcut by name.
Check that Siri is enabled for Gym Tracker in iOS Settings. Install and open the
updated app before testing; launch refreshes the App Shortcuts parameter index.
Speech recognition and device indexing still require physical-device checks.

Both the bundle display name and bundle name are **Gym Tracker**. The former
store name **VT Gym Tracker** remains a Siri app-name alias, so existing users
can say “Check the McComas crowds with VT Gym Tracker”. Bundle IDs,
repository identifiers, and Swift type names stay stable across updates.

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

For All Facilities the dialog reports all three records. For a specific facility, speech leads with percentage full and a short crowd description.
At the unchanged UI thresholds, below 50% is quiet, 50–under 75% is getting busy,
and 75% or more is busy. Counts and capacities remain in the typed result.
A climbing-wall count is reported separately. There are no forecasts, historical records, inferred opening hours, or Foundation Models features.

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

- [Get to know App Intents: phrases include applicationName](https://developer.apple.com/videos/play/wwdc2025/244/)
- [ShortcutsLink](https://developer.apple.com/documentation/appintents/shortcutslink)

## Natural crowd responses and gym choice

**Choose a Less Crowded Gym** is a separate background action. It fetches only
McComas and War Memorial and returns those two typed readings. Speech leads
with the choice and both percentages, for example “War Memorial is the better
pick for fewer crowds right now: 25% full, compared with McComas at 75%.” It
compares percentage full, not raw headcounts, since capacities differ. It does
not rank the bouldering wall alongside full-service gyms. Differences below one
percentage point are described as similar; exact capacity ties and two busy
gyms have explicit responses. If either fresh count is missing or cached, no
winner is chosen. Cached answers describe the last reading and its age rather
than claiming the count is current. The existing siri_crowds event also counts
these crowd-comparison requests, with the same bounded status values.

A single live response says “McComas is 75% full right now—it's busy.” Under 1%
but nonzero is spoken as “less than 1%” to avoid turning a small crowd into zero.
RecSports' count is retrieved at invocation; the source still publishes no
independent measurement timestamp or equipment/queue data.

Apple's guidance supports short, information-first dialogue, no repeated app
branding in the answer, and a small set of clear actions with familiar options:
- [Siri dialogue guidance](https://developer.apple.com/design/human-interface-guidelines/siri)
- [App Shortcuts design](https://developer.apple.com/design/human-interface-guidelines/app-shortcuts)
- [Phrase matching and app-name synonyms](https://developer.apple.com/videos/play/wwdc2023/10102/)
- [App-name synonyms, not arbitrary keywords](https://developer.apple.com/library/archive/qa/qa1950/_index.html)

The new VT Gyms name is a declared app nickname, not a global keyword or an
Apple/VT system integration. Automatic phrases still use applicationName.
Physical-device phrase matching must verify the nickname after installing the
new build. Personal shortcuts remain an option for arbitrary custom phrases.
