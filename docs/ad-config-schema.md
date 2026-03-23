# Ad Config Schema

The app loads sponsor config from the API at `https://gymtracker.jackhannon.net/api/ads`. Configure one active ad at a time — in practice you'll only ever have one live with `"active": true`. Manage ads via the [Admin UI](https://jackhannon.net/gymtracker-ads-admin.html) or by PUTting to the API with the `X-API-Key` header.

## Tiers

| Tier | Layout | `image_url` | Image height |
|------|--------|-------------|--------------|
| `text` | Logo (optional), headline, subline (optional), CTA | Omit or `null` | — |
| `banner` | Image on top, logo (optional), headline, subline (optional), CTA | Required | 140pt |
| `feature` | Image on top, logo (optional), headline, subline (optional), CTA | Required | 220pt |

The `tier` field drives the layout in `AdView`; banner and feature differ only by image height.

## Examples

**Tier 1 — Text only:**

```json
{
  "id": "sponsor_001",
  "tier": "text",
  "sponsor": "Benny's Coffee Co.",
  "logo_url": "https://your-cdn.com/logos/benny.png",
  "headline": "Study fuel. 10% off with your student ID.",
  "subline": "127 N Main St · Open 7am–10pm",
  "cta": "Get the deal",
  "destination_url": "https://bennyscoffee.com/vt",
  "active": true
}
```

**Tier 2 — Banner:**

```json
{
  "id": "sponsor_002",
  "tier": "banner",
  "sponsor": "Off Campus Bookstore",
  "image_url": "https://your-r2-or-cdn.com/ads/ocb_march.jpg",
  "logo_url": "https://your-cdn.com/logos/ocb.png",
  "headline": "Textbooks, gear & more. Free pickup in Blacksburg.",
  "subline": "Save on textbooks, VT gear & more.",
  "cta": "Shop now",
  "destination_url": "https://offcampusbookstore.com",
  "active": true
}
```

**Tier 3 — Feature:**

```json
{
  "id": "sponsor_003",
  "tier": "feature",
  "sponsor": "Sharkey's Billiards",
  "image_url": "https://your-r2-or-cdn.com/ads/sharkeys_march.jpg",
  "logo_url": "https://your-cdn.com/logos/sharkeys.png",
  "headline": "Post-workout happy hour. $3 drafts 4–7pm every weekday.",
  "subline": "123 N Main St · Pool, darts & more.",
  "cta": "See menu",
  "destination_url": "https://sharkeysbburg.com",
  "active": true
}
```

## Optional fields

- **`logo_url`**: Optional. Business logo shown to the left of headline/subline in all tiers. Square aspect recommended (e.g. 64×64 or 128×128).
- **`subline`**: Optional. Subheadline shown under headline in all tiers (e.g. address, hours, supporting copy).
- **`creative_version`**: Optional. Defaults to empty. Used for analytics.
- **`placement`**: Optional. Defaults to `"home_feed"`.
- **`start_at`** / **`end_at`**: Optional ISO8601 dates. Default to always-active when omitted.
