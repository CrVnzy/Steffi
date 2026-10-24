-- Private setup for the coupon book and daily mood check-ins.
-- Requires the existing public.gallery_members allow-list table.
-- Run this script once in the Supabase SQL Editor.
--
-- Privacy note: this public repository intentionally contains no member email addresses.
-- After running the script, use the Supabase Table Editor to add one row per allow-listed
-- email to public.couple_member_roles. Assign Yannik's account(s) person_key = 'yannik'
-- and Steffi's account(s) person_key = 'steffi'. In this project, both of Steffi's
-- approved addresses should map to 'steffi'. Use the exact lowercase emails from
-- public.gallery_members. This table has no client-side write permissions.

grant usage on schema public to authenticated;

create table public.couple_member_roles (
  email text primary key references public.gallery_members(email) on delete cascade,
  person_key text not null check (person_key in ('yannik', 'steffi'))
);

alter table public.couple_member_roles enable row level security;

create policy "members can read their own couple role"
  on public.couple_member_roles for select to authenticated
  using (email = lower(coalesce((select auth.jwt()) ->> 'email', '')));

revoke all privileges on table public.couple_member_roles from public, anon, authenticated;
grant select on public.couple_member_roles to authenticated;

create table public.couple_coupons (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(btrim(title)) between 1 and 100),
  emoji text not null default '🎁' check (char_length(btrim(emoji)) between 1 and 8),
  description text not null default '' check (char_length(description) <= 500),
  giver_person text not null check (giver_person in ('yannik', 'steffi')),
  recipient_person text not null check (recipient_person in ('yannik', 'steffi')),
  created_at timestamptz not null default now(),
  redeemed_at timestamptz,
  constraint couple_coupons_different_people check (giver_person <> recipient_person)
);

alter table public.couple_coupons enable row level security;

create policy "gallery members can view couple coupons"
  on public.couple_coupons for select to authenticated
  using (exists (
    select 1 from public.gallery_members gm
    where gm.email = lower(coalesce((select auth.jwt()) ->> 'email', ''))
  ));

create policy "members can create coupons for the other person"
  on public.couple_coupons for insert to authenticated
  with check (
    giver_person = coalesce((
      select cmr.person_key from public.couple_member_roles cmr
      where cmr.email = lower(coalesce((select auth.jwt()) ->> 'email', ''))
    ), '')
    and recipient_person <> giver_person
  );

create policy "only the intended recipient can redeem a coupon"
  on public.couple_coupons for update to authenticated
  using (
    redeemed_at is null
    and recipient_person = coalesce((
      select cmr.person_key from public.couple_member_roles cmr
      where cmr.email = lower(coalesce((select auth.jwt()) ->> 'email', ''))
    ), '')
  )
  with check (
    redeemed_at is not null
    and recipient_person = coalesce((
      select cmr.person_key from public.couple_member_roles cmr
      where cmr.email = lower(coalesce((select auth.jwt()) ->> 'email', ''))
    ), '')
  );

revoke all privileges on table public.couple_coupons from public, anon, authenticated;
grant select on public.couple_coupons to authenticated;
grant insert (title, emoji, description, giver_person, recipient_person) on public.couple_coupons to authenticated;
grant update (redeemed_at) on public.couple_coupons to authenticated;

create table public.couple_mood_checkins (
  id uuid primary key default gen_random_uuid(),
  person_key text not null check (person_key in ('yannik', 'steffi')),
  mood text not null check (mood in ('great', 'good', 'okay', 'low', 'hard')),
  note text not null default '' check (char_length(note) <= 300),
  checkin_date date not null,
  created_at timestamptz not null default now(),
  constraint couple_mood_checkins_one_per_person_per_day unique (person_key, checkin_date)
);

alter table public.couple_mood_checkins enable row level security;

create policy "gallery members can view shared mood checkins"
  on public.couple_mood_checkins for select to authenticated
  using (exists (
    select 1 from public.gallery_members gm
    where gm.email = lower(coalesce((select auth.jwt()) ->> 'email', ''))
  ));

create policy "members can add their own mood checkin"
  on public.couple_mood_checkins for insert to authenticated
  with check (
    person_key = coalesce((
      select cmr.person_key from public.couple_member_roles cmr
      where cmr.email = lower(coalesce((select auth.jwt()) ->> 'email', ''))
    ), '')
  );

create policy "members can update their own mood checkin"
  on public.couple_mood_checkins for update to authenticated
  using (
    person_key = coalesce((
      select cmr.person_key from public.couple_member_roles cmr
      where cmr.email = lower(coalesce((select auth.jwt()) ->> 'email', ''))
    ), '')
  )
  with check (
    person_key = coalesce((
      select cmr.person_key from public.couple_member_roles cmr
      where cmr.email = lower(coalesce((select auth.jwt()) ->> 'email', ''))
    ), '')
  );

revoke all privileges on table public.couple_mood_checkins from public, anon, authenticated;
grant select on public.couple_mood_checkins to authenticated;
grant insert (person_key, mood, note, checkin_date) on public.couple_mood_checkins to authenticated;
grant update (mood, note) on public.couple_mood_checkins to authenticated;
