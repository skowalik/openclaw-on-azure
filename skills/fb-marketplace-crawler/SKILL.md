---
name: fb-marketplace-crawler
description: Crawl Facebook Marketplace for specific items and notify when new listings are found
metadata: {"openclaw": {"requires": {"config": ["browser.enabled"]}, "emoji": "🛒"}}
---

# Facebook Marketplace Crawler

You are Red's deal-hunting skill. Your job is to search Facebook Marketplace for specific items and report new listings via WhatsApp.

## Search Profiles

### Profile: Ice Hockey Skates
- **Search terms**: "ice hockey skates size 11.5", "hockey skates 11.5"
- **Location**: Jersey City, NJ (ZIP 07307)
- **Radius**: 90 miles
- **Size filter**: Must be men's size 11.5 (also check for "11 1/2" or "11.5")
- **Max price**: Any (report all, but highlight deals under $100)

## How to Search

1. Use the browser tool to open Facebook Marketplace search URLs:
   - `https://www.facebook.com/marketplace/nyc/search/?query=hockey%20skates%2011.5&radius=145&exact=false`
   - Also try: `https://www.facebook.com/marketplace/nyc/search/?query=ice%20hockey%20skates&radius=145&exact=false`
   - The radius parameter is in km (145 km ≈ 90 miles). The `nyc` city slug covers the 07307 area.

2. Wait for the page to load fully, then take a snapshot.

3. Extract from each listing:
   - **Title** (full listing title)
   - **Price**
   - **Location**
   - **Link** (the listing URL)
   - **Posted** (how recently — "Just now", "1 hour ago", etc.)

4. Filter results:
   - MUST be ice hockey skates (not inline skates, roller skates, figure skates, or ski boots)
   - MUST be men's size 11.5 (or 11 1/2) — check title AND description
   - IGNORE listings that are clearly wrong sport or wrong size

## Tracking Seen Listings

Keep a running list of listing URLs you've already reported in `{baseDir}/seen.json`. Only report NEW listings you haven't seen before. Update `seen.json` after each run.

If `{baseDir}/seen.json` doesn't exist, create it as an empty array `[]` and treat all current listings as new.

## Output Format

For each NEW matching listing, format as:

```
🏒 NEW: [Title]
💰 Price: $[price]
📍 Location: [City, State]
🔗 Link: [URL]
⏰ Posted: [time ago]
```

If no new listings found, respond with:
"No new hockey skate listings found. Will check again later."

## Important Notes

- Facebook may show a login wall for some results — if so, note it and try the search URL directly
- Be respectful of rate limits — one search session every 30 minutes is fine
- If the page layout changes, adapt and still try to extract listing info
- Check both the listing title and the first few lines of description for size info
