-- Seed/update coaches in the athletes table.
--
-- This mirrors the S&C athlete roster seed style and is safe to run more than once:
-- 1) Existing coaches are matched by name (case-insensitive) and updated.
-- 2) Missing coaches are inserted.
--
-- Expected public.athletes columns used by the app:
--   name text, grade integer, groups text[], sport text, notes text, active_status boolean
--
-- Grade is set to null because the provided value is N/A.

begin;

with incoming (name, grade, groups, sport, notes, active_status) as (
  values
    ('Edwin', null::integer, array['Coach']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Mac', null::integer, array['Coach']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Kitchens', null::integer, array['Coach']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Stabach', null::integer, array['Coach']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Carson', null::integer, array['Coach']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('German', null::integer, array['Coach']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('McClendon', null::integer, array['Coach']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Crain', null::integer, array['Coach']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Scheffer', null::integer, array['Coach']::text[], 'Enter a Sport', 'Enter Notes', true)
), updated as (
  update public.athletes a
  set
    grade = i.grade,
    groups = i.groups,
    sport = i.sport,
    notes = i.notes,
    active_status = i.active_status
  from incoming i
  where lower(trim(a.name)) = lower(trim(i.name))
  returning a.name
)
insert into public.athletes (name, grade, groups, sport, notes, active_status)
select i.name, i.grade, i.groups, i.sport, i.notes, i.active_status
from incoming i
where not exists (
  select 1
  from public.athletes a
  where lower(trim(a.name)) = lower(trim(i.name))
);

commit;
