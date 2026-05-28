-- Coach login + audit setup for Eagle Strength
create table if not exists public.coach_users (
  id bigserial primary key,
  username text unique not null,
  password text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.coach_audit_logs (
  id bigserial primary key,
  coach_username text not null,
  action text not null,
  details text default '',
  created_at timestamptz not null default now()
);

-- starter login requested
insert into public.coach_users (username, password)
values ('Mike', 'mikey')
on conflict (username) do update set password = excluded.password;

-- recommended for frontend inserts/selects with anon key (adjust as desired)
alter table public.coach_users enable row level security;
alter table public.coach_audit_logs enable row level security;

drop policy if exists coach_users_select on public.coach_users;
create policy coach_users_select on public.coach_users for select using (true);

drop policy if exists coach_audit_insert on public.coach_audit_logs;
create policy coach_audit_insert on public.coach_audit_logs for insert with check (true);

drop policy if exists coach_audit_select on public.coach_audit_logs;
create policy coach_audit_select on public.coach_audit_logs for select using (true);
