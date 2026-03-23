# Sponsor Reporting (PostHog)

Use this runbook to create production sponsor KPI reports from PostHog, scoped by ad ID (e.g. `sponsor-2025-q1`).

## Events

The app emits these events:

- `ad_impression`
- `ad_tap`

Event properties:

- `ad_id` — unique campaign ID (used for client-scoped KPIs)
- `sponsor`
- `placement`
- `destination_host`
- `session_id`
- `creative_version`

## Admin Dashboard (Per-Ad KPIs)

The Ads Admin at [gymtracker.jackhannon.net/admin](https://gymtracker.jackhannon.net/admin) shows:

- **Overview banner:** Aggregate impressions, clicks, CTR (last 7d) across all ads
- **Ad cards:** Per-ad 7d stats (impressions, clicks, CTR) when PostHog is configured
- **KPI panel:** Selected ad’s 7d metrics in the Schedule tab sidebar

Stats are scoped by `ad_id`. Use a consistent ad ID (e.g. `sponsor-2025-q1`) so you can track and present metrics per client.

## PostHog Insights (Ad-ID Scoped)

Create these insights in PostHog and pin them to a dashboard named **Sponsor KPI**. Use **Breakdown: `ad_id`** so metrics are per campaign.

1. **Daily Impressions**
   - Metric: Count of `ad_impression`
   - Breakdown: `ad_id`
   - Interval: Day
   - Filter: `placement = home_feed`

2. **Daily Taps**
   - Metric: Count of `ad_tap`
   - Breakdown: `ad_id`
   - Interval: Day
   - Filter: `placement = home_feed`

3. **CTR**
   - Metric: Formula
   - Numerator: Count(`ad_tap`)
   - Denominator: Count(`ad_impression`)
   - Formula: `A/B`
   - Breakdown: `ad_id`
   - Filter: `placement = home_feed`

## SQL Export (Per-Ad, Custom Date Range)

For client reports with a custom date range, run this in PostHog **SQL** (or Query API):

```sql
SELECT
  properties.ad_id AS ad_id,
  countIf(event = 'ad_impression') AS impressions,
  countIf(event = 'ad_tap') AS clicks
FROM events
WHERE event IN ('ad_impression', 'ad_tap')
  AND timestamp >= '2025-01-01' AND timestamp < '2025-01-08'
  AND coalesce(properties.placement, 'home_feed') = 'home_feed'
GROUP BY properties.ad_id
ORDER BY impressions DESC
```

Replace the date range with the campaign window. Export as CSV. Compute CTR as `(clicks / impressions) * 100` in your spreadsheet. Share the row for that client’s `ad_id`.

## Client Report Workflow

1. **One ad per client:** Use a unique `ad_id` per sponsor/campaign (e.g. `orbyt-2025-q1`).
2. **During campaign:** Check Admin dashboard or PostHog for live 7d stats.
3. **End of campaign:**
   - Set dashboard date range to the campaign period.
   - Export insights as PNG (charts) and CSV (numbers).
   - Or run the SQL above for the exact campaign dates.
4. **Client summary:** Send impressions, clicks, CTR, and top-performing creative version (if A/B tested).

## Campaign Lifecycle

- **Launch:** Publish new ad via Admin UI or PUT to `https://gymtracker.jackhannon.net/api/ads`. Verify `ad_impression` and `ad_tap` in PostHog Live Events.
- **Close:** Set ad `active` to `false` (or expire `end_at`) and export final report.
- **Emergency stop:** Toggle Show Sponsored Offers off in app settings to hide the slot immediately.
