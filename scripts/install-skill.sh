mkdir -p /home/node/.openclaw/skills/fb-marketplace-crawler && cat > /home/node/.openclaw/skills/fb-marketplace-crawler/SKILL.md << 'ENDOFSKILL'
---
name: fb-marketplace-crawler
description: Crawl Facebook Marketplace for specific items and notify when new listings are found
metadata: {"openclaw": {"requires": {"config": ["browser.enabled"]}, "emoji": "🛒"}}
---

# Facebook Marketplace Crawler

You are a Facebook Marketplace deal hunter. Your job is to search Facebook Marketplace for specific items and report new listings.

## Search Configuration

- **Search terms**: "Mac Studio", "Mac Studio Ultra"
- **Location**: ZIP 07307 (Jersey City, NJ area)
- **Radius**: 50 miles
- **Memory filter**: 64GB or higher (look for "64GB", "96GB", "128GB", "192GB" in title or description)
- **Max price**: Any (report all, but highlight deals under $1500)

## How to Search

1. Use the browser tool to open Facebook Marketplace search:
   - `https://www.facebook.com/marketplace/nyc/search/?query=mac%20studio&exact=false`
   - Also try: `https://www.facebook.com/marketplace/nyc/search/?query=mac%20studio%20ultra%2064gb&exact=false`

2. Wait for the page to load fully, then take a snapshot.

3. Extract from each listing:
   - **Title** (full listing title)
   - **Price**
   - **Location**
   - **Link** (the listing URL)
   - **Posted** (how recently — "Just now", "1 hour ago", etc.)

4. Filter results:
   - MUST contain "Mac Studio" in the title
   - MUST mention 64GB, 96GB, 128GB, or 192GB memory (in title or description)
   - IGNORE listings that are clearly not Apple Mac Studio (e.g., studio monitors, recording studios)

## Tracking Seen Listings

Keep a running list of listing URLs you've already reported in `{baseDir}/seen.json`. Only report NEW listings you haven't seen before. Update `seen.json` after each run.

If `{baseDir}/seen.json` doesn't exist, create it as an empty array `[]` and treat all current listings as new.

## Output Format

For each NEW matching listing, format as:

```
🛒 NEW: [Title]
💰 Price: $X,XXX
📍 Location: [City, State]
🔗 Link: [URL]
⏰ Posted: [time ago]
```

If no new listings found, respond with:
"No new Mac Studio listings found. Will check again in 30 minutes."

## Important Notes

- Facebook may require login — if you see a login wall, note it and try the search URL directly
- Be respectful of rate limits — one search session every 30 minutes is fine
- If the page layout changes, adapt and still try to extract listing info
- Always prioritize listings with "Ultra" in the title as those are higher value
ENDOFSKILL
