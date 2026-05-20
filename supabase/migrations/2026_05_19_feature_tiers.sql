-- Migration: 2026-05-19 — feature_flags tier column (replaces enabled bool)
--
-- Lets the admin mark each section as one of:
--   'off'  — hidden for everyone (kill switch)
--   'free' — visible to all users
--   'pro'  — visible only to Plus-subscribed parents; others see an upsell
--
-- This generalises the previous boolean `enabled` into a three-state lifecycle
-- so the same row can power both kill-switching AND Pro-tier gating without a
-- second table.

alter table public.feature_flags
  add column if not exists tier text not null default 'free'
    check (tier in ('off','free','pro'));

-- Backfill from the legacy enabled column.
update public.feature_flags
   set tier = case when enabled then 'free' else 'off' end
 where tier = 'free';

-- (We keep the enabled column for a release cycle so old clients don't break.
-- A follow-up migration can drop it once everyone is on the new app version.)

-- Update the convenience view to reflect what kid-facing app should hide.
-- App reads this; if a key is here, render the tile. If not, hide it.
create or replace view public.feature_flags_visible as
  select key, tier
  from public.feature_flags
  where tier in ('free','pro');

grant select on public.feature_flags_visible to anon, authenticated;

-- Convenience: which tier the current user is in. The 'is_pro' check
-- mirrors how lib/core/providers/premium_provider.dart sees the entitlements
-- table.
create or replace function public.current_user_tier() returns text
  language sql security definer set search_path = public as $$
  select case
    when exists (
      select 1 from public.entitlements e
       where e.user_id = auth.uid()
         and e.is_premium = true
         and (e.premium_until is null or e.premium_until > now())
    ) then 'pro'
    else 'free'
  end;
$$;

grant execute on function public.current_user_tier() to anon, authenticated;
