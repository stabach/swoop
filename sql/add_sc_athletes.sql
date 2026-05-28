-- Seed/update S&C athlete roster.
--
-- This script is safe to run more than once:
-- 1) Existing athletes are matched by full name (case-insensitive) and updated.
-- 2) Missing athletes are inserted.
--
-- Expected public.athletes columns used by the app:
--   name text, grade integer, groups text[], sport text, notes text, active_status boolean

begin;

with incoming (name, grade, groups, sport, notes, active_status) as (
  values
    ('Lukas Bayes', 7, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Wyatt Albritton', 7, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Caleb Williams', 8, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Noah Williams', 6, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Parker Woolley', 12, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('William Atkinson', 10, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Lucas Ray', 7, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Hunter Rubin', 6, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Douglas Kelly', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Kason Perryman', 8, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Bennett Perryman', 6, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Ryan Cole', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Preston Reina', 7, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Jack Purifoy', 7, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Carter Metting', 10, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Tate West', 6, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Lincoln Turner', 10, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Thomas Diebold', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Blake Watson', 6, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Corynne Ledet', 7, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Caleb Holmes', 7, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Hudson Sheffield', 10, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Spencer Sheffield', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Colton Cooper', 11, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Kylie Young', 10, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Nick Wallace', 11, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Alexander Perez', 11, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Alayna Perez', 7, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Harrison Millis', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Dominic Sette', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Westley Morgan', 10, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Samantha Morgan', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Lucas Cordova', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Brady Poss', 12, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Aden Angapen', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Anna Angapen', 11, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Isaac Hantz', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Eli Hantz', 11, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Will Johnson', 12, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Holden Propst', 10, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Elijah Feaster', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Brayden Tibbetts', 12, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Gavin Sbrusch', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Joe LeCompte', 8, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Charlie Frank', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Nathaniel Tanyi', 7, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Rachel Tanyi', 6, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Olivia Tanyi', 5, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('MJ Ryans', 7, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Logan Brewster', 6, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Kellen Canady', 10, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Wells Watson', 5, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Eleanor Watson', 8, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Zane Holmes', 7, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Jack Mckinney', 10, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Jaylen Rodriguez', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Parker Alexander', 8, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Dylan Alexander', 6, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Reagan Jarrett', 12, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Ty Garth', 5, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Zach Sherman', 6, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Kallee Clayton', 7, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Cannon Jones', 7, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Alex Tilly', 11, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Caitlyn Kon', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Cassandra Vinh', 10, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Ava Pekar', 11, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Matthew Preng', 10, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Beck Brown', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Cameron Miller', 10, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Brody Miller', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Landon Kuranoff', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Ian Smith', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Molly Brennan', 8, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Jill Brennan', 6, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('William Lukefahr', 11, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Molly Applegate', 7, array['S&C - Middle School']::text[], 'Enter a Sport', 'Enter Notes', true),
    ('Zoe Henry', 9, array['S&C - High School']::text[], 'Enter a Sport', 'Enter Notes', true)
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
