# Recreation events in Siri and Shortcuts

The app exposes **Find Upcoming Recreation Events** and **Get Recreation Event
Details** alongside **Check Current Crowds**. All three complete without opening
the app. Example phrases use the installed name, Gym Tracker:

- “Find upcoming events with Gym Tracker.”
- “Find recreation events with Gym Tracker.”
- “Get event details with Gym Tracker.”
- “Get details for [event title] with Gym Tracker.”

The first action accepts optional **From** and **Before** dates and a result limit
(default 5, range 1–20). It includes ongoing events that overlap the half-open
interval, excludes events already ended at retrieval time, sorts by start time
then stable source identity, and reports returned and matching counts separately.
A requested start in the past becomes the retrieval time. An end at or before
the effective start is invalid. These are absolute date instants supplied by
Shortcuts, not a new natural-language or AI search implementation.

## Factual result contract

The search returns a typed result containing an array of selectable event
entities, effective date interval, limit, returned count, optional matching count,
status, fetch/check times, optional cache age, optional rejected-record count,
availability detail, source feed URL, and source limitation. An unavailable feed
has no known matching count; a successfully empty feed has a matching count of 0.

Each event exposes stable source identity, optional title, start/end dates,
America/New_York time-zone identity, optional raw source time-zone text, location,
organizer, raw price text, event URL, freshness/status, and source feed URL.
Unknown values remain absent. Missing price does **not** mean free. A source
location such as “Private Location (sign in to display)” remains exactly that;
no location, description, suitability, availability, or registration claim is
invented. The feed currently supplies no descriptions, so none are generated.

The source is the app's existing CampusGroups **Recreational Sports** endpoint,
whose request is limited to 40 records. Matching counts refer to readable records
in that available feed, not every campus event. Malformed event rows are skipped
with an exposed rejected-record count and spoken warning; a wholly malformed
feed is unavailable, never “no events.” Valid date separators are ignored.

Dates are interpreted in the configured campus calendar, America/New_York.
Supplied Eastern daylight/standard time text must agree with the date's actual
offset. Unsupported supplied zones and unparseable date formats are rejected.
Overnight ranges use the same campus calendar rather than the device's calendar.

Event identity uses `campusgroups:<eventId>`, falling back to the absolute source
event URL if the ID is absent. Entity queries resolve exact identities, suggest
upcoming events, and match titles literally using localized substring matching.
Repeated titles remain separate choices; no arbitrary first-title selection is
made. Details refetch by identity instead of trusting a previously passed entity;
an event absent from the current available feed returns unavailable detail fields.

## Shared service and cache

`EventsService` and the extracted `CampusGroupsEventsParser` are shared by Siri
and the existing `EventsViewModel`; the service does not initialize UI or a network
monitor. Requests use an ephemeral URLSession with HTTP caching disabled, a
12-second request timeout, and a 15-second resource timeout.

The app's existing `cachedEvents.json` now stores a small envelope with events,
original successful retrieval date and rejected-record count. On failure Siri may
reuse this existing cache for up to 24 hours, excludes events that have since
ended, and exposes/speaks its actual age. Age is checked after the failed request.
Failures and cached responses never overwrite the success date. Future-dated and
expired caches are unavailable. A cached empty successful feed remains a cached
empty result, distinct from unavailable data.

Legacy bare-array caches remain readable for the app's immediate display but
cannot provide verified Siri freshness; they become eligible after a real fetch.
The UI retains its current events cards, initial loading state and offline cache
behavior. There is no new history, chatbot, forecast or Foundation Models feature.

## Verification

```sh
swift test --jobs 1 --scratch-path /tmp/vtgym-crowds-tests
VTGYM_LIVE_CHECK=1 swift test --jobs 1 --scratch-path /tmp/vtgym-crowds-tests --filter 'testLive'
python3 scripts/verify_crowds_metadata.py '/path/to/Gym Tracker RC.app'
```

The deterministic suite injects fixture networking and a fixed clock; real-network
checks run separately. Build the Release app and embedded widget, then the Watch
scheme serially. iOS 17 and watchOS 10 deployment targets remain unchanged.

A physical device is still needed to confirm spoken event-title disambiguation,
Shortcuts result-property extraction, and Siri invocation while the app is
backgrounded or the device is locked. Metadata extraction and host-side intent
execution cannot prove those behaviors.

Apple references: [EntityQuery](https://developer.apple.com/documentation/appintents/entityquery),
[EntityStringQuery](https://developer.apple.com/documentation/appintents/entitystringquery),
[AppEntity](https://developer.apple.com/documentation/appintents/appentity),
[AppShortcutsProvider](https://developer.apple.com/documentation/appintents/appshortcutsprovider).
