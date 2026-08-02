<wizard-report>
# PostHog post-wizard report

The wizard has completed a deep integration of PostHog analytics into the Gym Tracker iOS app. The PostHog iOS SDK (v3.57.0) was added via Swift Package Manager, initialized in the app entry point with application lifecycle event capture, and event tracking was instrumented across 9 source files covering campus ID workflows, ad performance, settings interactions, and service reliability.

## Changes summary

- **`project.pbxproj`** — Added `posthog-ios` SPM package reference (`XCRemoteSwiftPackageReference`), product dependency (`XCSwiftPackageProductDependency`), and build file linked to the `Gym Tracker (RC)` target.
- **`Gym Tracker (RC).xcscheme`** — Added `POSTHOG_PROJECT_TOKEN` and `POSTHOG_HOST` environment variables to the Run LaunchAction.
- **`Gym_Tracker__RC_App.swift`** — Added `PostHogEnv` enum (reads from scheme env vars) and PostHog SDK initialization with `captureApplicationLifecycleEvents = true`.
- **`ContentView.swift`** — Added `settings_opened` capture when the settings toolbar button is tapped.
- **`AdViewModel.swift`** — Added `ad_impression` capture (de-duplicated per session) and `ad_tapped` capture with sponsor/placement/tier properties.
- **`BarcodeScannerView.swift`** — Added `campus_id_scanned` capture on successful barcode scan.
- **`ManualIDInputView.swift`** — Added `campus_id_entered_manually` capture when a 9-digit ID is saved.
- **`BarcodeDisplayView.swift`** — Added `campus_id_displayed` capture when the barcode overlay appears.
- **`SettingsView.swift`** — Added `campus_id_removed`, `face_id_toggled` (with `enabled` property), and `theme_changed` (with `theme` property) capture.
- **`GymService.swift`** — Added `gym_occupancy_fetch_failed` capture (iOS-only, guarded with `#if os(iOS)`) when all three facility fetches return nil.
- **`EventsViewModel.swift`** — Added `events_fetch_failed` capture with a `reason` property (`network_error`, `no_data`, or `parse_failed`) at each failure branch.

## Events

| Event | Description | File |
|-------|-------------|------|
| `campus_id_scanned` | User successfully scans a campus ID barcode using the camera scanner | `Gym Tracker (RC)/BarCode Scanner/BarcodeScannerView.swift` |
| `campus_id_entered_manually` | User saves a manually entered 9-digit campus ID number | `Gym Tracker (RC)/BarCode Scanner/ManualIDInputView.swift` |
| `campus_id_displayed` | User views their campus ID barcode overlay | `Gym Tracker (RC)/BarCode Scanner/BarcodeDisplayView.swift` |
| `campus_id_removed` | User removes their saved campus ID from the app | `Gym Tracker (RC)/SettingsView.swift` |
| `face_id_toggled` | User enables or disables Face ID protection for campus ID access | `Gym Tracker (RC)/SettingsView.swift` |
| `theme_changed` | User changes the app theme (Auto, Light, or Dark) | `Gym Tracker (RC)/SettingsView.swift` |
| `ad_impression` | A sponsored ad becomes visible on the dashboard for the first time | `Gym Tracker (RC)/Ads/AdViewModel.swift` |
| `ad_tapped` | User taps the CTA button on a sponsored ad | `Gym Tracker (RC)/Ads/AdViewModel.swift` |
| `gym_occupancy_fetch_failed` | All gym occupancy fetches fail (all three facilities return nil) | `Gym Tracker (RC)/Services/GymService.swift` |
| `events_fetch_failed` | RSS events feed fails to load | `Gym Tracker (RC)/Events/EventsViewModel.swift` |
| `settings_opened` | User opens the settings sheet from the toolbar | `Gym Tracker (RC)/ContentView.swift` |

## Next steps

We've built some insights and a dashboard for you to keep an eye on user behavior, based on the events we just instrumented:

- [Analytics basics dashboard](https://us.posthog.com/project/396850/dashboard/1509412)
- [Campus ID Adoption Funnel](https://us.posthog.com/project/396850/insights/HciKfxLX) — funnel from scan/manual entry to barcode display
- [Ad Impressions vs Taps](https://us.posthog.com/project/396850/insights/pTVuPYxJ) — daily trend of ad CTR
- [Campus ID Removals](https://us.posthog.com/project/396850/insights/ixfpvvov) — weekly churn signal for the ID feature
- [Gym Occupancy Fetch Failures](https://us.posthog.com/project/396850/insights/CEJq3frm) — daily backend reliability tracker
- [Settings Engagement](https://us.posthog.com/project/396850/insights/AVXW2id9) — weekly settings feature usage breakdown

### Agent skill

We've left an agent skill folder in your project. You can use this context for further agent development when using Claude Code. This will help ensure the model provides the most up-to-date approaches for integrating PostHog.

</wizard-report>
