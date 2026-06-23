# swoop

## Tutorials API

The Tutorials page uses a server-side YouTube Data API proxy at `/api/tutorials`.
Set this environment variable in the hosting platform before using tutorial search:

```text
YOUTUBE_API_KEY=your_key_here
```

GitHub Pages serves the app as static files and does not run `/api/tutorials`.
When that API route is unavailable, the Tutorials page falls back to embedded
YouTube how-to searches so athletes do not hit a dead error state.
