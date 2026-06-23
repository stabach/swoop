const YOUTUBE_SEARCH_URL = 'https://www.googleapis.com/youtube/v3/search';
const YOUTUBE_VIDEOS_URL = 'https://www.googleapis.com/youtube/v3/videos';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
};

function json(status: number, payload: unknown) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 's-maxage=900, stale-while-revalidate=3600',
    },
  });
}

function parseIsoDurationToSeconds(value: string | undefined) {
  const match = String(value || '').match(/^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$/);
  if (!match) return null;
  return (parseInt(match[1] || '0', 10) * 3600) + (parseInt(match[2] || '0', 10) * 60) + parseInt(match[3] || '0', 10);
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'GET') return json(405, { error: 'Method not allowed' });

  const apiKey = Deno.env.get('YOUTUBE_API_KEY');
  if (!apiKey) {
    console.error('Missing YOUTUBE_API_KEY environment variable');
    return json(500, { error: 'Tutorial search is not configured' });
  }

  const url = new URL(req.url);
  const rawTerm = String(url.searchParams.get('q') || '').trim();
  if (!rawTerm) return json(400, { error: 'Missing search term' });

  const query = `How to ${rawTerm}`;
  try {
    const searchParams = new URLSearchParams({
      key: apiKey,
      part: 'snippet',
      q: query,
      type: 'video',
      maxResults: '10',
      videoDuration: 'short',
      videoEmbeddable: 'true',
      safeSearch: 'strict',
      order: 'relevance',
    });
    const searchResponse = await fetch(`${YOUTUBE_SEARCH_URL}?${searchParams}`);
    if (!searchResponse.ok) {
      console.error('YouTube search failed', searchResponse.status, await searchResponse.text());
      return json(502, { error: 'Could not load tutorial videos right now' });
    }
    const searchData = await searchResponse.json();
    const ids = (searchData.items || [])
      .map((item: any) => item?.id?.videoId)
      .filter(Boolean);

    if (!ids.length) return json(200, { query, videos: [] });

    const videoParams = new URLSearchParams({
      key: apiKey,
      part: 'snippet,contentDetails,status',
      id: ids.join(','),
    });
    const videoResponse = await fetch(`${YOUTUBE_VIDEOS_URL}?${videoParams}`);
    if (!videoResponse.ok) {
      console.error('YouTube videos lookup failed', videoResponse.status, await videoResponse.text());
      return json(502, { error: 'Could not load tutorial videos right now' });
    }
    const videoData = await videoResponse.json();
    const order = new Map(ids.map((id: string, idx: number) => [id, idx]));

    const videos = (videoData.items || [])
      .filter((item: any) => item.status?.embeddable !== false)
      .map((item: any) => {
        const durationSeconds = parseIsoDurationToSeconds(item.contentDetails?.duration);
        const snippet = item.snippet || {};
        const thumbnail = snippet.thumbnails?.medium?.url || snippet.thumbnails?.high?.url || snippet.thumbnails?.default?.url || '';
        return {
          id: item.id,
          title: snippet.title || 'Exercise Tutorial',
          channelTitle: snippet.channelTitle || '',
          thumbnail,
          durationSeconds,
          isShort: durationSeconds !== null && durationSeconds <= 60,
          url: `https://www.youtube.com/shorts/${item.id}`,
        };
      })
      .sort((a: any, b: any) => (order.get(a.id) ?? 99) - (order.get(b.id) ?? 99))
      .slice(0, 5);

    return json(200, { query, videos });
  } catch (error) {
    console.error('Tutorial search error', error);
    return json(500, { error: 'Could not load tutorial videos right now' });
  }
});
