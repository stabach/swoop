const YOUTUBE_SEARCH_URL = 'https://www.googleapis.com/youtube/v3/search';
const YOUTUBE_VIDEOS_URL = 'https://www.googleapis.com/youtube/v3/videos';

function sendJson(res, status, payload) {
  res.statusCode = status;
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  res.setHeader('Cache-Control', 's-maxage=900, stale-while-revalidate=3600');
  res.end(JSON.stringify(payload));
}

function parseIsoDurationToSeconds(value) {
  const match = String(value || '').match(/^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$/);
  if (!match) return null;
  return (parseInt(match[1] || '0', 10) * 3600) + (parseInt(match[2] || '0', 10) * 60) + parseInt(match[3] || '0', 10);
}

module.exports = async function handler(req, res) {
  if (req.method !== 'GET') {
    res.setHeader('Allow', 'GET');
    return sendJson(res, 405, { error: 'Method not allowed' });
  }

  const apiKey = process.env.YOUTUBE_API_KEY;
  if (!apiKey) {
    console.error('Missing YOUTUBE_API_KEY environment variable');
    return sendJson(res, 500, { error: 'Tutorial search is not configured' });
  }

  const rawTerm = String(req.query?.q || '').trim();
  if (!rawTerm) return sendJson(res, 400, { error: 'Missing search term' });

  const query = `How to ${rawTerm}`;
  try {
    const searchParams = new URLSearchParams({
      key: apiKey,
      part: 'snippet',
      q: query,
      type: 'video',
      maxResults: '10',
      videoDuration: 'short',
      safeSearch: 'strict',
      order: 'relevance'
    });
    const searchResponse = await fetch(`${YOUTUBE_SEARCH_URL}?${searchParams}`);
    if (!searchResponse.ok) {
      console.error('YouTube search failed', searchResponse.status, await searchResponse.text());
      return sendJson(res, 502, { error: 'Could not load tutorial videos right now' });
    }
    const searchData = await searchResponse.json();
    const ids = (searchData.items || [])
      .map(item => item?.id?.videoId)
      .filter(Boolean);

    if (!ids.length) return sendJson(res, 200, { query, videos: [] });

    const videoParams = new URLSearchParams({
      key: apiKey,
      part: 'snippet,contentDetails',
      id: ids.join(',')
    });
    const videoResponse = await fetch(`${YOUTUBE_VIDEOS_URL}?${videoParams}`);
    if (!videoResponse.ok) {
      console.error('YouTube videos lookup failed', videoResponse.status, await videoResponse.text());
      return sendJson(res, 502, { error: 'Could not load tutorial videos right now' });
    }
    const videoData = await videoResponse.json();
    const order = new Map(ids.map((id, idx) => [id, idx]));

    const videos = (videoData.items || [])
      .map(item => {
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
          url: `https://www.youtube.com/shorts/${item.id}`
        };
      })
      .sort((a, b) => (order.get(a.id) ?? 99) - (order.get(b.id) ?? 99))
      .slice(0, 5);

    return sendJson(res, 200, { query, videos });
  } catch (error) {
    console.error('Tutorial search error', error);
    return sendJson(res, 500, { error: 'Could not load tutorial videos right now' });
  }
};
