# swoop

## Tutorials API

The Tutorials page uses a server-side YouTube Data API proxy so the API key is
not exposed in browser code. On GitHub Pages, deploy the included Supabase Edge
Function at `supabase/functions/tutorials` and set this secret before using
tutorial search:

```text
YOUTUBE_API_KEY=your_key_here
```

Deploy or redeploy the function after setting the secret:

```bash
supabase functions deploy tutorials --project-ref ispmelxwebnhnoflbeoj --no-verify-jwt
```

## Athlete Login API

Athlete credentials are created by the Supabase Edge Function at
`supabase/functions/athlete-auth`. Apply the migration first so athlete auth
fields, credential storage, and RLS policies exist:

```bash
supabase db push
supabase functions deploy athlete-auth --project-ref ispmelxwebnhnoflbeoj
```

The function creates real Supabase Auth users for athletes and stores the
coach-visible temporary password in `public.athlete_login_credentials`, which is
protected by coach-only RLS.
