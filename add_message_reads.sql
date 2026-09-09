-- ============================================================
-- Recipes app — read receipts for the team (group) chat: who has
-- read each message, and whether everyone has ("Όλοι"). Personal
-- messages (DMs) already have this via dm_messages.read_at from an
-- earlier step — this file is the team-chat equivalent. Run this
-- once in Supabase: Project → SQL Editor → New query → paste this
-- whole file → Run.
-- (Safe to run even if you already ran earlier SQL files — every
-- statement here only touches new things or replaces itself.)
-- ============================================================

-- One row per (message, person who has read it).
create table if not exists public.message_reads (
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (message_id, user_id)
);
alter table public.message_reads enable row level security;

-- Everyone signed in can see who has read a team message (that's the
-- whole point of the "Είδαν: ..." / "Όλοι" receipt), but a person can
-- only ever record THEIR OWN read — nobody can mark a message read on
-- someone else's behalf.
drop policy if exists "message_reads: signed-in users can read all" on public.message_reads;
create policy "message_reads: signed-in users can read all"
  on public.message_reads for select
  using (auth.role() = 'authenticated');

drop policy if exists "message_reads: insert own" on public.message_reads;
create policy "message_reads: insert own"
  on public.message_reads for insert
  with check (auth.role() = 'authenticated' and auth.uid() = user_id);

-- Turn on live updates, so the "Είδαν"/"Όλοι" line under your own
-- messages updates instantly for everyone as teammates read them,
-- without anyone needing to refresh.
do $$
begin
  alter publication supabase_realtime add table public.message_reads;
exception when duplicate_object then null;
end $$;

-- ============================================================
-- Nothing else to run — the app already marks messages as read the
-- moment they're visible in an open team-chat screen, and renders the
-- receipt line under each of your own messages.
-- ============================================================
