-- Coach login + audit setup for Eagle Strength using Supabase Auth.
-- IMPORTANT:
--   1) Create each coach in Supabase Authentication first.
--   2) Copy that auth.users.id UUID into public.coach_users.auth_user_id.
--   3) Do not store plaintext passwords in public tables.

begin;

create table if not exists public.coach_users (
  id bigserial primary key,
  username text unique not null,
  email text unique,
  auth_user_id uuid unique references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Safe upgrades for older installs that originally had username/password rows.
alter table public.coach_users add column if not exists email text;
alter table public.coach_users add column if not exists auth_user_id uuid references auth.users(id) on delete cascade;
create unique index if not exists coach_users_auth_user_id_key on public.coach_users(auth_user_id);
create unique index if not exists coach_users_email_key on public.coach_users(email);
alter table public.coach_users drop column if exists password;

create table if not exists public.coach_audit_logs (
  id bigserial primary key,
  auth_user_id uuid references auth.users(id) on delete set null,
  coach_username text not null,
  action text not null,
  details text default '',
  created_at timestamptz not null default now()
);

alter table public.coach_audit_logs add column if not exists auth_user_id uuid references auth.users(id) on delete set null;

alter table public.coach_users enable row level security;
alter table public.coach_audit_logs enable row level security;

-- Helper used by broader app-table RLS policies if you choose to apply it to athletes/logs/templates.
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

-- Remove the old broad policies from the original plaintext-password version.
drop policy if exists coach_users_select on public.coach_users;
drop policy if exists coach_audit_insert on public.coach_audit_logs;
drop policy if exists coach_audit_select on public.coach_audit_logs;

-- Coach profiles are only visible to the linked authenticated user.
drop policy if exists "Users can view their own coach profile" on public.coach_users;
create policy "Users can view their own coach profile"
on public.coach_users
for select
to authenticated
using (
  auth.uid() is not null
  and auth.uid() = auth_user_id
);

-- Audit logs can only be inserted by the authenticated coach they belong to.
drop policy if exists "Authenticated coaches can insert their own audit logs" on public.coach_audit_logs;
create policy "Authenticated coaches can insert their own audit logs"
on public.coach_audit_logs
for insert
to authenticated
with check (
  auth.uid() is not null
  and auth.uid() = auth_user_id
);

-- Coaches can view their own audit history. Add a separate admin policy later if needed.
drop policy if exists "Authenticated coaches can view their own audit logs" on public.coach_audit_logs;
create policy "Authenticated coaches can view their own audit logs"
on public.coach_audit_logs
for select
to authenticated
using (
  auth.uid() is not null
  and auth.uid() = auth_user_id
);

commit;

-- Example profile link after creating the user in Authentication > Users:
-- update public.coach_users
-- set email = 'mike@school.com', auth_user_id = 'PASTE-AUTH-USERS-ID-HERE'
-- where lower(username) = lower('Mike');
