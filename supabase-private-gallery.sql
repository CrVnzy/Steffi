-- Private gallery bootstrap for the Steffi website.
-- Run once in a fresh Supabase project. Do not add member emails to this public file.

create table public.gallery_members (
  email text primary key check (email = lower(btrim(email))),
  created_at timestamptz not null default now()
);

create table public.gallery_photos (
  id uuid primary key default gen_random_uuid(),
  object_path text not null unique,
  caption text not null default '' check (char_length(caption) <= 300),
  memory_date date,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

alter table public.gallery_members enable row level security;
alter table public.gallery_photos enable row level security;

create policy "members can read their own membership"
  on public.gallery_members for select to authenticated
  using (email = lower(coalesce((select auth.jwt() ->> 'email'), '')));

create policy "members can view shared photos"
  on public.gallery_photos for select to authenticated
  using (exists (
    select 1 from public.gallery_members gm
    where gm.email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
  ));

create policy "members can add shared photos"
  on public.gallery_photos for insert to authenticated
  with check (exists (
    select 1 from public.gallery_members gm
    where gm.email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
  ));

create policy "members can edit shared photos"
  on public.gallery_photos for update to authenticated
  using (exists (
    select 1 from public.gallery_members gm
    where gm.email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
  ))
  with check (exists (
    select 1 from public.gallery_members gm
    where gm.email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
  ));

create policy "members can delete shared photos"
  on public.gallery_photos for delete to authenticated
  using (exists (
    select 1 from public.gallery_members gm
    where gm.email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
  ));

grant usage on schema public to authenticated;
revoke all privileges on table public.gallery_members from public, anon, authenticated;
grant select on public.gallery_members to authenticated;
revoke all privileges on table public.gallery_photos from public, anon, authenticated;
grant select on public.gallery_photos to authenticated;
grant insert (object_path, caption, memory_date) on public.gallery_photos to authenticated;
grant update (caption, memory_date) on public.gallery_photos to authenticated;
grant delete on public.gallery_photos to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'couple-photos',
  'couple-photos',
  false,
  15728640,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic', 'image/avif']
);

create policy "gallery members can view couple photos"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'couple-photos'
    and exists (
      select 1 from public.gallery_members gm
      where gm.email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
    )
  );

create policy "gallery members can upload couple photos"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'couple-photos'
    and exists (
      select 1 from public.gallery_members gm
      where gm.email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
    )
  );

create policy "gallery members can edit couple photos"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'couple-photos'
    and exists (
      select 1 from public.gallery_members gm
      where gm.email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
    )
  )
  with check (
    bucket_id = 'couple-photos'
    and exists (
      select 1 from public.gallery_members gm
      where gm.email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
    )
  );

create policy "gallery members can delete couple photos"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'couple-photos'
    and exists (
      select 1 from public.gallery_members gm
      where gm.email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
    )
  );
