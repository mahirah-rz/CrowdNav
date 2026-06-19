-- CrowdNav Supabase schema + RLS
-- Run this once in Supabase SQL Editor.
-- Safe to re-run: uses create table if not exists and add column if not exists.

create extension if not exists "pgcrypto";

-- =========================
-- Profiles
-- =========================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  student_id text not null default '',
  email text not null default '',
  phone text not null default '',
  department text not null default '',
  program text not null default '',
  blood_group text not null default '',
  role text not null default 'student',
  avatar_url text,
  assigned_route text,
  office_section text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists office_section text;
alter table public.profiles add column if not exists assigned_route text;
alter table public.profiles add column if not exists avatar_url text;

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_authenticated" on public.profiles;
create policy "profiles_select_authenticated"
on public.profiles for select
to authenticated
using (true);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "profiles_update_own_or_admin" on public.profiles;
create policy "profiles_update_own_or_admin"
on public.profiles for update
to authenticated
using (
  auth.uid() = id
  or exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
)
with check (
  auth.uid() = id
  or exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  )
);

-- =========================
-- Device tokens for FCM
-- =========================
create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  fcm_token text not null unique,
  platform text not null default 'android',
  role text not null default 'student',
  department text,
  program text,
  office_section text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.device_tokens add column if not exists role text not null default 'student';
alter table public.device_tokens add column if not exists department text;
alter table public.device_tokens add column if not exists program text;
alter table public.device_tokens add column if not exists office_section text;
alter table public.device_tokens add column if not exists is_active boolean not null default true;
alter table public.device_tokens add column if not exists updated_at timestamptz not null default now();

alter table public.device_tokens enable row level security;

drop policy if exists "device_tokens_select_own_or_admin" on public.device_tokens;
create policy "device_tokens_select_own_or_admin"
on public.device_tokens for select
to authenticated
using (
  user_id = auth.uid()
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
);

drop policy if exists "device_tokens_upsert_own" on public.device_tokens;
create policy "device_tokens_upsert_own"
on public.device_tokens for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "device_tokens_update_own" on public.device_tokens;
create policy "device_tokens_update_own"
on public.device_tokens for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- =========================
-- Announcements
-- =========================
create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  target_role text not null default 'all',
  target_department text not null default 'all',
  target_program text not null default 'all',
  priority text not null default 'normal',
  sent_push boolean not null default false,
  push_success_count integer not null default 0,
  push_failure_count integer not null default 0,
  push_error text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.announcements add column if not exists target_role text not null default 'all';
alter table public.announcements add column if not exists sent_push boolean not null default false;
alter table public.announcements add column if not exists push_success_count integer not null default 0;
alter table public.announcements add column if not exists push_failure_count integer not null default 0;
alter table public.announcements add column if not exists push_error text;
alter table public.announcements add column if not exists created_by uuid references public.profiles(id) on delete set null;

alter table public.announcements enable row level security;

drop policy if exists "announcements_select_authenticated" on public.announcements;
create policy "announcements_select_authenticated"
on public.announcements for select
to authenticated
using (true);

drop policy if exists "announcements_insert_admin" on public.announcements;
create policy "announcements_insert_admin"
on public.announcements for insert
to authenticated
with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
);

drop policy if exists "announcements_update_admin" on public.announcements;
create policy "announcements_update_admin"
on public.announcements for update
to authenticated
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

-- =========================
-- Bus locations
-- =========================
create table if not exists public.bus_locations (
  bus_id text primary key,
  latitude double precision not null,
  longitude double precision not null,
  route_name text not null default '',
  driver_name text not null default '',
  driver_phone text not null default '',
  speed_kmph double precision,
  heading double precision,
  updated_at timestamptz not null default now()
);

alter table public.bus_locations enable row level security;

drop policy if exists "bus_locations_select_authenticated" on public.bus_locations;
create policy "bus_locations_select_authenticated"
on public.bus_locations for select
to authenticated
using (true);

drop policy if exists "bus_locations_upsert_driver_admin" on public.bus_locations;
create policy "bus_locations_upsert_driver_admin"
on public.bus_locations for insert
to authenticated
with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('driver', 'admin'))
);

drop policy if exists "bus_locations_update_driver_admin" on public.bus_locations;
create policy "bus_locations_update_driver_admin"
on public.bus_locations for update
to authenticated
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('driver', 'admin')))
with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('driver', 'admin')));

drop policy if exists "bus_locations_delete_driver_admin" on public.bus_locations;
create policy "bus_locations_delete_driver_admin"
on public.bus_locations for delete
to authenticated
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('driver', 'admin')));

-- =========================
-- Complaints and replies
-- =========================
create table if not exists public.complaints (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  user_name text not null default 'Unknown',
  user_department text not null default '',
  category text not null default 'general',
  subject text not null,
  description text not null,
  priority text not null default 'normal',
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.complaints enable row level security;

drop policy if exists "complaints_select_own_or_admin" on public.complaints;
create policy "complaints_select_own_or_admin"
on public.complaints for select
to authenticated
using (
  user_id = auth.uid()
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
);

drop policy if exists "complaints_insert_own" on public.complaints;
create policy "complaints_insert_own"
on public.complaints for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "complaints_update_admin" on public.complaints;
create policy "complaints_update_admin"
on public.complaints for update
to authenticated
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

create table if not exists public.complaint_replies (
  id uuid primary key default gen_random_uuid(),
  complaint_id uuid not null references public.complaints(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  sender_name text not null default 'Unknown',
  sender_role text not null default 'student',
  message text not null,
  created_at timestamptz not null default now()
);

alter table public.complaint_replies enable row level security;

drop policy if exists "complaint_replies_select_related" on public.complaint_replies;
create policy "complaint_replies_select_related"
on public.complaint_replies for select
to authenticated
using (
  exists (
    select 1 from public.complaints c
    where c.id = complaint_id
    and (
      c.user_id = auth.uid()
      or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
    )
  )
);

drop policy if exists "complaint_replies_insert_related" on public.complaint_replies;
create policy "complaint_replies_insert_related"
on public.complaint_replies for insert
to authenticated
with check (
  sender_id = auth.uid()
  and exists (
    select 1 from public.complaints c
    where c.id = complaint_id
    and (
      c.user_id = auth.uid()
      or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
    )
  )
);

select pg_notify('pgrst', 'reload schema');
