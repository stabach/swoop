begin;

create or replace function public.is_coach()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.coach_users cu
    where cu.auth_user_id = auth.uid()
  );
$$;

alter table public.athletes add column if not exists username text;
alter table public.athletes add column if not exists auth_user_id uuid references auth.users(id) on delete set null;
alter table public.athletes add column if not exists role text not null default 'athlete';
alter table public.athletes add column if not exists credentials_generated_at timestamptz;
alter table public.athletes add column if not exists updated_at timestamptz not null default now();

update public.athletes
set role = 'coach'
where role = 'athlete'
  and exists (
    select 1
    from unnest(coalesce(groups, array[]::text[])) as g
    where lower(g) = 'coach'
  );

create unique index if not exists athletes_username_key
on public.athletes (lower(username))
where username is not null;

create unique index if not exists athletes_auth_user_id_key
on public.athletes (auth_user_id)
where auth_user_id is not null;

create table if not exists public.athlete_login_credentials (
  athlete_id text primary key,
  username text unique not null,
  temporary_password text not null,
  auth_user_id uuid unique references auth.users(id) on delete cascade,
  generated_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.athletes enable row level security;
alter table public.athlete_login_credentials enable row level security;

drop policy if exists "Coaches can manage athletes" on public.athletes;
drop policy if exists "Athletes can view own profile" on public.athletes;

create policy "Coaches can manage athletes"
on public.athletes
for all
to authenticated
using (public.is_coach())
with check (public.is_coach());

create policy "Athletes can view own profile"
on public.athletes
for select
to authenticated
using (auth.uid() is not null and auth.uid() = auth_user_id);

drop policy if exists "Coaches can manage athlete credentials" on public.athlete_login_credentials;

create policy "Coaches can manage athlete credentials"
on public.athlete_login_credentials
for all
to authenticated
using (public.is_coach())
with check (public.is_coach());

alter table public.workout_logs enable row level security;

drop policy if exists "Coaches can manage workout logs" on public.workout_logs;
drop policy if exists "Athletes can view own workout logs" on public.workout_logs;
drop policy if exists "Athletes can insert own workout logs" on public.workout_logs;
drop policy if exists "Athletes can update own workout logs" on public.workout_logs;

create policy "Coaches can manage workout logs"
on public.workout_logs
for all
to authenticated
using (public.is_coach())
with check (public.is_coach());

create policy "Athletes can view own workout logs"
on public.workout_logs
for select
to authenticated
using (
  exists (
    select 1
    from public.athletes a
    where a.id = workout_logs.athlete_id
      and a.auth_user_id = auth.uid()
  )
);

create policy "Athletes can insert own workout logs"
on public.workout_logs
for insert
to authenticated
with check (
  date::text = ((now() at time zone 'America/Chicago')::date)::text
  and
  exists (
    select 1
    from public.athletes a
    where a.id = workout_logs.athlete_id
      and a.auth_user_id = auth.uid()
  )
);

create policy "Athletes can update own workout logs"
on public.workout_logs
for update
to authenticated
using (
  date::text = ((now() at time zone 'America/Chicago')::date)::text
  and
  exists (
    select 1
    from public.athletes a
    where a.id = workout_logs.athlete_id
      and a.auth_user_id = auth.uid()
  )
)
with check (
  date::text = ((now() at time zone 'America/Chicago')::date)::text
  and
  exists (
    select 1
    from public.athletes a
    where a.id = workout_logs.athlete_id
      and a.auth_user_id = auth.uid()
  )
);

alter table public.workout_templates enable row level security;

drop policy if exists "Authenticated users can view workout templates" on public.workout_templates;
drop policy if exists "Users can view permitted workout templates" on public.workout_templates;
drop policy if exists "Coaches can manage workout templates" on public.workout_templates;

create policy "Users can view permitted workout templates"
on public.workout_templates
for select
to authenticated
using (
  public.is_coach()
  or (
    day_name like 'date_workout:%'
    and coalesce(template_json->>'date', template_json->>'workout_date') = ((now() at time zone 'America/Chicago')::date)::text
    and (
      lower(coalesce(template_json->>'teamName', template_json->>'team_name', template_json->>'sportTeam', template_json->>'sport_team', template_json->>'team', template_json->>'sport', '')) in ('all', 'all teams')
      or lower(coalesce(template_json->>'teamName', template_json->>'team_name', template_json->>'sportTeam', template_json->>'sport_team', template_json->>'team', template_json->>'sport', '')) in (
        select lower(t.team_name)
        from public.athletes a
        cross join lateral unnest(array_remove(array_append(coalesce(a.groups, array[]::text[]), coalesce(a.sport, '')), '')) as t(team_name)
        where a.auth_user_id = auth.uid()
      )
    )
  )
);

create policy "Coaches can manage workout templates"
on public.workout_templates
for all
to authenticated
using (public.is_coach())
with check (public.is_coach());

alter table public.attendance_logs enable row level security;

drop policy if exists "Coaches can manage attendance logs" on public.attendance_logs;

create policy "Coaches can manage attendance logs"
on public.attendance_logs
for all
to authenticated
using (public.is_coach())
with check (public.is_coach());

alter table public.calendar_notes enable row level security;

drop policy if exists "Coaches can manage calendar notes" on public.calendar_notes;

create policy "Coaches can manage calendar notes"
on public.calendar_notes
for all
to authenticated
using (public.is_coach())
with check (public.is_coach());

commit;
