import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const ATHLETE_EMAIL_DOMAIN = 'athletes.eaglestrength.local';
const PASSWORD_WORDS = ['Eagle', 'Lift', 'Strong', 'Train', 'Power', 'Squat', 'Bench', 'Sprint'];

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(status: number, payload: unknown) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
    },
  });
}

function cleanNamePart(value: string) {
  return String(value || '').toLowerCase().replace(/[^a-z0-9]/g, '');
}

function usernameBaseForAthlete(name: string) {
  const parts = String(name || '').trim().split(/\s+/).filter(Boolean);
  const first = cleanNamePart(parts[0] || 'athlete');
  const last = cleanNamePart(parts[parts.length - 1] || first || 'user');
  const base = `${first.slice(0, 1)}${last}`.replace(/[^a-z0-9]/g, '');
  return base || `athlete${Math.floor(Math.random() * 90) + 10}`;
}

function twoDigits() {
  return String(Math.floor(Math.random() * 100)).padStart(2, '0');
}

function threeDigits() {
  return String(Math.floor(Math.random() * 900) + 100);
}

function generatePassword() {
  const word = PASSWORD_WORDS[Math.floor(Math.random() * PASSWORD_WORDS.length)];
  return `${word}${threeDigits()}`;
}

function emailForUsername(username: string) {
  return `${username}@${ATHLETE_EMAIL_DOMAIN}`;
}

function isCoachLikeAthlete(athlete: any) {
  const role = String(athlete?.role || '').toLowerCase();
  const groups = Array.isArray(athlete?.groups) ? athlete.groups : [];
  return role === 'coach' || role === 'admin' || groups.some((g: string) => String(g).toLowerCase() === 'coach');
}

async function requireCoach(req: Request, supabaseUrl: string, anonKey: string, serviceKey: string) {
  const authHeader = req.headers.get('Authorization') || '';
  const client = createClient(supabaseUrl, anonKey, { global: { headers: { Authorization: authHeader } } });
  const { data: userData, error: userError } = await client.auth.getUser();
  if (userError || !userData?.user) throw new Error('Authentication required');

  const admin = createClient(supabaseUrl, serviceKey);
  const { data: coach, error: coachError } = await admin
    .from('coach_users')
    .select('id,username,auth_user_id')
    .eq('auth_user_id', userData.user.id)
    .maybeSingle();
  if (coachError || !coach) throw new Error('Coach access required');
  return { admin, coach, user: userData.user };
}

async function buildUniqueUsername(admin: any, athlete: any) {
  const base = usernameBaseForAthlete(athlete?.name || '');
  const { data } = await admin.from('athletes').select('username');
  const existing = new Set((data || []).map((row: any) => String(row.username || '').toLowerCase()).filter(Boolean));

  for (let i = 0; i < 250; i += 1) {
    const candidate = `${base}${twoDigits()}`;
    if (!existing.has(candidate)) return candidate;
  }
  return `${base}${twoDigits()}`;
}

async function fetchCredential(admin: any, athleteId: string) {
  const { data } = await admin
    .from('athlete_login_credentials')
    .select('username,temporary_password,auth_user_id')
    .eq('athlete_id', athleteId)
    .maybeSingle();
  return data || null;
}

async function ensureCredentials(admin: any, athleteId: string, options: { resetPassword?: boolean } = {}) {
  const { data: athlete, error: athleteError } = await admin
    .from('athletes')
    .select('*')
    .eq('id', athleteId)
    .maybeSingle();
  if (athleteError || !athlete) throw new Error('Athlete not found');
  if (isCoachLikeAthlete(athlete)) {
    return { athlete, credentials: null, skipped: true };
  }

  const existingCredential = await fetchCredential(admin, athleteId);
  const username = athlete.username || existingCredential?.username || await buildUniqueUsername(admin, athlete);
  const password = options.resetPassword || !existingCredential?.temporary_password
    ? generatePassword()
    : existingCredential.temporary_password;
  let authUserId = athlete.auth_user_id || existingCredential?.auth_user_id || null;

  if (!authUserId) {
    const { data: authData, error: createError } = await admin.auth.admin.createUser({
      email: emailForUsername(username),
      password,
      email_confirm: true,
      user_metadata: {
        role: 'athlete',
        athlete_id: athleteId,
        username,
        name: athlete.name || '',
      },
      app_metadata: {
        role: 'athlete',
      },
    });
    if (createError || !authData?.user?.id) throw new Error(createError?.message || 'Could not create athlete login');
    authUserId = authData.user.id;
  } else if (options.resetPassword || !existingCredential?.temporary_password) {
    const { error: updateError } = await admin.auth.admin.updateUserById(authUserId, { password });
    if (updateError) throw new Error(updateError.message || 'Could not reset athlete password');
  }

  const { data: updatedAthlete, error: updateAthleteError } = await admin
    .from('athletes')
    .update({
      username,
      auth_user_id: authUserId,
      role: 'athlete',
      credentials_generated_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('id', athleteId)
    .select('*')
    .single();
  if (updateAthleteError) throw new Error(updateAthleteError.message || 'Could not update athlete');

  const { error: credentialError } = await admin
    .from('athlete_login_credentials')
    .upsert({
      athlete_id: athleteId,
      username,
      temporary_password: password,
      auth_user_id: authUserId,
      generated_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }, { onConflict: 'athlete_id' });
  if (credentialError) throw new Error(credentialError.message || 'Could not save athlete credentials');

  return {
    athlete: updatedAthlete,
    credentials: { username, password },
    skipped: false,
  };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json(405, { error: 'Method not allowed' });

  const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') || '';
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
  if (!supabaseUrl || !anonKey || !serviceKey) return json(500, { error: 'Athlete auth is not configured' });

  try {
    const { admin } = await requireCoach(req, supabaseUrl, anonKey, serviceKey);
    const body = await req.json().catch(() => ({}));
    const action = String(body.action || '');

    if (action === 'ensure') {
      const athleteId = String(body.athleteId || '').trim();
      if (!athleteId) return json(400, { error: 'Missing athleteId' });
      return json(200, await ensureCredentials(admin, athleteId));
    }

    if (action === 'reset-password') {
      const athleteId = String(body.athleteId || '').trim();
      if (!athleteId) return json(400, { error: 'Missing athleteId' });
      return json(200, await ensureCredentials(admin, athleteId, { resetPassword: true }));
    }

    if (action === 'backfill') {
      const { data: athletes, error } = await admin.from('athletes').select('*').order('name');
      if (error) throw new Error(error.message || 'Could not load athletes');
      const updated = [];
      let createdCount = 0;
      for (const athlete of athletes || []) {
        if (isCoachLikeAthlete(athlete)) continue;
        if (athlete.username && athlete.auth_user_id) continue;
        const result = await ensureCredentials(admin, String(athlete.id));
        if (!result.skipped && result.athlete) {
          updated.push(result.athlete);
          createdCount += 1;
        }
      }
      return json(200, { createdCount, athletes: updated });
    }

    return json(400, { error: 'Unknown action' });
  } catch (error) {
    console.error('Athlete auth error', error);
    return json(403, { error: error instanceof Error ? error.message : 'Athlete auth failed' });
  }
});
