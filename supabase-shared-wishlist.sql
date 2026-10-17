-- Shared wishlist and completed-moment archive for the Steffi website.
-- The app reuses gallery_members for allow-listed access and couple-photos for private images.

create table public.couple_wishes (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(btrim(title)) between 1 and 120),
  created_at timestamptz not null default now(),
  is_completed boolean not null default false,
  completed_at date,
  completion_note text not null default '' check (char_length(completion_note) <= 1000),
  object_path text unique,
  constraint couple_wishes_date_requires_completion check (is_completed or completed_at is null)
);

alter table public.couple_wishes enable row level security;

create policy "gallery members can view shared wishes"
  on public.couple_wishes for select to authenticated
  using (exists (
    select 1 from public.gallery_members gm
    where gm.email = lower(coalesce((select auth.jwt()) ->> 'email', ''))
  ));

create policy "gallery members can add shared wishes"
  on public.couple_wishes for insert to authenticated
  with check (exists (
    select 1 from public.gallery_members gm
    where gm.email = lower(coalesce((select auth.jwt()) ->> 'email', ''))
  ));

create policy "gallery members can update shared wishes"
  on public.couple_wishes for update to authenticated
  using (exists (
    select 1 from public.gallery_members gm
    where gm.email = lower(coalesce((select auth.jwt()) ->> 'email', ''))
  ))
  with check (exists (
    select 1 from public.gallery_members gm
    where gm.email = lower(coalesce((select auth.jwt()) ->> 'email', ''))
  ));

grant usage on schema public to authenticated;
revoke all privileges on table public.couple_wishes from public, anon, authenticated;
grant select on public.couple_wishes to authenticated;
grant insert (title) on public.couple_wishes to authenticated;
grant update (is_completed, completed_at, completion_note, object_path) on public.couple_wishes to authenticated;
