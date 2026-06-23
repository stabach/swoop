begin;

alter table public.workout_logs add column if not exists workout_id text;
alter table public.workout_logs add column if not exists workout_item_id text;
alter table public.workout_logs add column if not exists sport_team text;
alter table public.workout_logs add column if not exists set_entries jsonb not null default '[]'::jsonb;
alter table public.workout_logs add column if not exists created_by uuid;
alter table public.workout_logs add column if not exists created_by_role text;
alter table public.workout_logs add column if not exists created_at timestamptz not null default now();
alter table public.workout_logs add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'workout_logs_athlete_date_workout_item_key'
  ) then
    alter table public.workout_logs
      add constraint workout_logs_athlete_date_workout_item_key
      unique (athlete_id, date, workout_id, workout_item_id);
  end if;
end $$;

drop policy if exists "Athletes can delete own workout logs" on public.workout_logs;

create policy "Athletes can delete own workout logs"
on public.workout_logs
for delete
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
);

commit;
