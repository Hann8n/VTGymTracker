# Campaign and product analytics

Gym Tracker 1.5.3 (20) emits a small set of first-party events to the existing Cloudflare ads service. The admin dashboard provides a visual Overview, campaign management, detailed Events with CSV export, and per-campaign reports that can be saved as PDF or downloaded as HTML.

Ads now accept `sponsored_label`: `Sponsored` (the default for absent/null values), `Partner`, `Student Organization`, or an empty string to hide the subtitle. Sponsor name remains independently visible. The dashboard preview, API normalization, iOS decoding, and cached config encoding all preserve the empty-string choice.

Release builds on physical iOS devices record foreground sessions, event and Campus ID opens (without content), Settings opens, three Siri actions with freshness/status, qualified ad impressions, and CTA taps. Debug builds, Simulator builds, host tests, and `dev_*` creatives do not send production data. There is no analytics SDK or new third-party package.

Qualified impressions require at least half the card area in the scroll viewport for one continuous second while active and without a known covering sheet. Counts are capped at one per campaign creative per session. Sessions reset on app restart or after 30 minutes in background. Reach means random installation IDs, not people. CTA taps are interactions, not confirmed website visits. The reports explain coverage, formulas, and retention; they do not claim MRC accreditation, conversions, revenue, or ROI.

Users can stop future analytics in Settings → Share Usage Analytics. Disabling also removes the local installation ID; reenabling generates a new one. No Campus ID data, email, name, precise location, event title, or search interval is collected. Delivery is best effort with a two-second timeout, no retry backlog, and no dependency on analytics availability for core functionality. Cloudflare D1 retains raw events for 366 days plus the daily cleanup interval.

The included privacy manifest declares unlinked Device ID, Product Interaction, and Advertising Data for analytics, no tracking, and the app's own/shared-group UserDefaults usage. The public privacy policy is updated alongside the app. App Store privacy answers should reflect these categories before a public App Store submission.

Backend implementation, deployment steps, query definitions, and research references are in the portfolio repository at `gymtracker/docs/analytics-reporting.md`.
