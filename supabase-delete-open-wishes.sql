-- Allow allow-listed gallery members to remove wishlist entries that are still open.
-- Completed wishes remain protected and stay in the shared memory archive.

create policy "gallery members can delete open wishes"
  on public.couple_wishes for delete to authenticated
  using (
    not is_completed
    and exists (
      select 1 from public.gallery_members gm
      where gm.email = lower(coalesce((select auth.jwt()) ->> 'email', ''))
    )
  );

grant delete on public.couple_wishes to authenticated;
