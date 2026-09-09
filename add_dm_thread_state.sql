-- ============================================================
-- Recipes app — per-person conversation state for personal
-- messages: mute / archive / delete a DM thread from your own
-- list without touching the other person's copy or the messages
-- themselves. Run this once in Supabase: Project → SQL Editor →
-- New query → paste this whole file → Run.
-- (Safe to run even if you already ran earlier SQL files — every
-- statement here only touches new things or replaces itself.)
-- ============================================================

-- One row per (you, other person). archived_at/deleted_at are
-- timestamps rather than plain true/false flags on purpose: a
-- conversation you archived or removed reappears in your list on its
-- own the moment a NEWER message arrives (same as Messages/WhatsApp),
-- because the app compares that message's time against these
-- timestamps instead of hiding the thread forever.
create table if not exists public.dm_thread_state (
  user_id uuid not null references public.profiles(id) on delete cascade,
  other_id uuid not null references public.profiles(id) on delete cascade,
  muted boolean not null default false,
  archived_at timestamptz,
  deleted_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (user_id, other_id)
);
alter table public.dm_thread_state enable row level security;

-- Strictly your own rows — nobody, not even the other person in the
-- thread, can see or change how YOU have muted/archived/deleted it.
drop policy if exists "dm_thread_state: read own" on public.dm_thread_state;
create policy "dm_thread_state: read own"
  on public.dm_thread_state for select
  using (auth.uid() = user_id);

drop policy if exists "dm_thread_state: insert own" on public.dm_thread_state;
create policy "dm_thread_state: insert own"
  on public.dm_thread_state for insert
  with check (auth.uid() = user_id);

drop policy if exists "dm_thread_state: update own" on public.dm_thread_state;
create policy "dm_thread_state: update own"
  on public.dm_thread_state for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Live updates aren't needed here (only the owning person's own client
-- ever reads their rows, and it re-fetches right after it writes one),
-- so no realtime publication is added for this table.

-- ============================================================
-- The send-push Edge Function also reads this table (with the
-- service-role key, which bypasses RLS) to skip sending a push for a
-- muted DM thread — that needs send-push/index.ts redeployed after
-- this file is run; see the accompanying files/instructions for that
-- step.
-- ============================================================
