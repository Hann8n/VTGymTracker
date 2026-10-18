# Athletic dashboard style system

Visual and interaction rules for the main iPhone dashboard (`ContentView` and related views). The goal is a cohesive “field board” atmosphere: VT-tinted depth behind neutral, legible cards.

Virginia Tech is not associated with this project.

## Layer model (bottom → top)

1. **`DashboardScrollContainer`** — A semantic system background per scrolling pane; neutral surfaces keep content legible in either appearance.
2. **Screen chrome** — Large title (“Gym Tracker”), section headers, staggered sections.
3. **Frosted cards** — **`CardMaterialBackground`**: `thinMaterial` plus a monochrome diagonal wash (not brand colors). Keeps occupancy and events readable.
4. **In-card structure** — Full-bleed **`FullBleedDivider`** between stacked rows (events list, ad image/copy split).

## Layout tokens

Defined in **`DashboardLayout`** (single source of truth):

| Token | Value | Use |
|--------|--------|-----|
| `horizontalGutter` | `16` | Content inset inside cards, section headers, event rows, ads |
| `cardVerticalPadding` | `18` | Default vertical padding for card bodies |
| `offlineOpacity` | `0.55` | Opacity when offline (with grayscale) |

Apply frosted surface + offline treatment with **`dashboardCardChrome(networkMonitor:)`** so facility cards, events block, and ads stay consistent.

## Typography

- Prefer **`.fontWidth(.condensed)`** for athletic, dense headlines and meta.
- **Section / facility labels**: uppercase, **`.caption` or `.subheadline` + `.bold`**, **`tracking` ~0.9** (see `FacilityOccupancyCard`, `DashboardSectionHeader`).
- **Hero occupancy count**: large **`.system(size: 40, weight: .black)`**, condensed, **`.monospacedDigit()`**.
- **Percentages and counts**: semibold/medium condensed; tertiary color for capacity denominator.

## Color

- **Occupancy bar and thresholds**: use `Color.occupancyColor(for:)` and existing green / orange / maroon assets — **do not change 50% / 75% breakpoints** (project rule).
- **Field board**: `CustomMaroon` / `CustomOrange` at low opacity in `AthleticFieldBoardBackground` only.
- **Cards**: neutral material + grayscale wash; avoid putting strong maroon fills on full card faces.

## Motion

- **`MotionPolicy`** derives animations from `accessibilityReduceMotion`.
- **Entry / updates**: `entryAnimation`, `updateAnimation`, `transition` — pass the same `motionPolicy` into views that animate numbers or swap content.
- **Staggered sections**: **`staggeredAppear(index:motionPolicy:)`** — capped delay ~12 steps × 55 ms; skips motion when Reduce Motion is on.

## Component map

| Type | Role |
|------|------|
| `DashboardContentLayout` | Compact feed or independent occupancy/events panes using the horizontal size class; system arrangement on iOS 27.1+ |
| `DashboardScrollContainer` | Scroll view with semantic background and stable section anchors |
| `FacilityOccupancyCard` | Single facility: label, count, %, `SegmentedProgressBar` |
| `EventsSectionBlock` | Compact header with smaller source label; stacks at larger text sizes, followed by list / empty / error |
| `DashboardSectionHeader` | Title + optional subtitle row |
| `FullBleedDivider` | 1 pt `separator` edge-to-edge inside a card |
| `CardMaterialBackground` | Reusable frosted fill |
| `StaggeredAppear` | Section entrance |
| `EventDayGroup` | Agenda layout: compact date gutter beside a title/time stack, top-aligned with 12 pt outer inset; stacks at accessibility sizes |
| `EventDateTile` | Soft-filled weekday/day box without a border or month label; Today is accented, distinct from plain event times |
| `EventCard` | Standard-width semibold headline and centered outlink, 4 pt title/time gap, 52 pt minimum touch height; supporting details wrap at Dynamic Type sizes |
| (loading) | Cached events show instantly and refresh in place; a plain `ProgressView` only when nothing is cached. No shimmers or skeletons. |
| `AdView` | Sponsored block; matches gutter + frosted chrome |

## Adding a new dashboard block

1. Use **`DashboardContentLayout`** at the dashboard root, and **`DashboardScrollContainer`** once per scrolling pane.
2. Use **`DashboardLayout.horizontalGutter`** / **`cardVerticalPadding`** for insets unless there is a strong reason not to.
3. For a full-width card, use **`dashboardCardChrome(networkMonitor:)`** after your content padding.
4. Separate stacked rows inside one card with **`FullBleedDivider`**.
5. For a new section in `ContentView`, add **`staggeredAppear`** with the next index and pass **`motionPolicy`**.

## Related files (main target)

`DashboardLayout.swift`, `DashboardContentLayout.swift`, `DashboardScrollContainer.swift`, `AthleticFieldBoardBackground.swift`, `CardMaterialBackground.swift`, `FacilityOccupancyCard.swift`, `EventsSectionBlock.swift`, `DashboardSectionHeader.swift`, `FullBleedDivider.swift`, `StaggeredAppear.swift`, `MotionPolicy.swift`, `SegmentedProgressBar.swift`, `Events/EventCard.swift`, `AdView.swift`, `ContentView.swift`

## Events reference

The agenda structure follows the day-grouped Schedule pattern described in [Google Calendar’s iPhone guide](https://support.google.com/calendar/answer/6110849?co=GENIE.Platform%3DiOS&hl=en), adapted to the dashboard’s neutral surfaces and condensed section headings. The date uses a medium-weight day number rather than the occupancy hero-number style. Event titles use standard-width headlines, with smaller secondary time text.

Event dates sit in compact, softly filled boxes in a reserved leading column, without a border or visible month label. Center weekday and proportional day-number text in the same width, without extra tracking. Spoken dates retain their full context.


## Expanded displays and iPhone Duo

Follow [Apple’s adaptive arrangement guidance](https://developer.apple.com/videos/play/tech-talks/111463/). Compact windows keep the existing occupancy → sponsor → events feed. Regular-width windows put occupancy and events in separate, independently scrolling panes, with the sponsor below occupancy. A single app title and system toolbar sit outside the arrangement; the events pane removes the spacing intended for a section following another card.

On iOS 27.1+, `ArrangementView` with the split style lets the system select a horizontal or vertical split and account for the fold. Keep both axes available so events remain reachable in tall configurations. Earlier systems use equal-width columns in regular width. Select layouts using size classes rather than model names, screen bounds, or device orientation. View models and presentation state remain owned by `ContentView`; section scroll anchors live in the adaptive layout so resizing does not recreate data owners.
