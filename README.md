# swoop

## Tutorials API

The Tutorials page uses a server-side YouTube Data API proxy so the API key is
not exposed in browser code. On GitHub Pages, deploy the included Supabase Edge
Function at `supabase/functions/tutorials` and set this secret before using
tutorial search:

```text
YOUTUBE_API_KEY=your_key_here
```
