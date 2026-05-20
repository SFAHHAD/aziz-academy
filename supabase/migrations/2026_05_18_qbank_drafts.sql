-- Migration: 2026-05-18 — Q-Bank drafts table + admin allowlist
--
-- Purpose: enable admin CRUD over quiz content via the /x9k2-admin-portal.
-- Bundled JSON pools stay the canonical source of truth; this table is an
-- overlay the app reads at startup and merges on top (draft wins per
-- (pool_id, id) key). Audit log captures every change for traceability.
--
-- To apply:
--   1. Open the Supabase project SQL editor.
--   2. Paste this file. Run.
--   3. Bootstrap your own admin row:
--        insert into public.admin_users (uid, email)
--          values ('<your-supabase-auth-uid>', 'you@example.com');
--   4. Verify: select * from public.admin_users;
--

-- =============================================================================
-- 1. admin_users allowlist
-- =============================================================================

create table if not exists public.admin_users (
  uid uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  added_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;

-- Admins can read the allowlist (so the UI can show "you are admin / you are not").
drop policy if exists admin_users_read on public.admin_users;
create policy admin_users_read on public.admin_users
  for select using (
    auth.role() = 'authenticated' and
    exists (select 1 from public.admin_users a where a.uid = auth.uid())
  );

-- =============================================================================
-- 2. qbank_drafts — admin-edited content overrides
-- =============================================================================

create table if not exists public.qbank_drafts (
  pool_id text not null,
  id text not null,
  status text not null default 'draft'
    check (status in ('draft','review','published','archived')),
  payload jsonb not null,
  author_uid uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (pool_id, id)
);

create index if not exists qbank_drafts_status_idx on public.qbank_drafts (status);
create index if not exists qbank_drafts_updated_idx on public.qbank_drafts (updated_at desc);

alter table public.qbank_drafts enable row level security;

-- Read: any authenticated user who is in the admin allowlist.
drop policy if exists qbank_drafts_read on public.qbank_drafts;
create policy qbank_drafts_read on public.qbank_drafts
  for select using (
    auth.role() = 'authenticated' and
    exists (select 1 from public.admin_users a where a.uid = auth.uid())
  );

-- Write: same gate. Client validation enforces schema; server gate enforces
-- authorisation.
drop policy if exists qbank_drafts_write on public.qbank_drafts;
create policy qbank_drafts_write on public.qbank_drafts
  for all using (
    auth.role() = 'authenticated' and
    exists (select 1 from public.admin_users a where a.uid = auth.uid())
  ) with check (
    auth.role() = 'authenticated' and
    exists (select 1 from public.admin_users a where a.uid = auth.uid())
  );

-- Auto-update updated_at on UPDATE.
create or replace function public.qbank_drafts_touch() returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists qbank_drafts_touch_trg on public.qbank_drafts;
create trigger qbank_drafts_touch_trg
  before update on public.qbank_drafts
  for each row execute function public.qbank_drafts_touch();

-- =============================================================================
-- 3. qbank_audit — append-only change log
-- =============================================================================

create table if not exists public.qbank_audit (
  id bigserial primary key,
  pool_id text not null,
  question_id text not null,
  action text not null check (action in ('create','update','delete','publish','archive')),
  before jsonb,
  after jsonb,
  actor_uid uuid not null references auth.users(id),
  at timestamptz not null default now()
);

create index if not exists qbank_audit_at_idx on public.qbank_audit (at desc);
create index if not exists qbank_audit_pool_idx on public.qbank_audit (pool_id, question_id, at desc);

alter table public.qbank_audit enable row level security;

drop policy if exists qbank_audit_read on public.qbank_audit;
create policy qbank_audit_read on public.qbank_audit
  for select using (
    auth.role() = 'authenticated' and
    exists (select 1 from public.admin_users a where a.uid = auth.uid())
  );

-- No direct insert/update/delete — only the trigger writes here.
drop policy if exists qbank_audit_insert on public.qbank_audit;
create policy qbank_audit_insert on public.qbank_audit
  for insert with check (false);  -- block all client writes

-- Trigger on qbank_drafts logs every change.
create or replace function public.qbank_drafts_log() returns trigger
  language plpgsql security definer set search_path = public as $$
begin
  insert into public.qbank_audit (pool_id, question_id, action, before, after, actor_uid)
  values (
    coalesce(new.pool_id, old.pool_id),
    coalesce(new.id, old.id),
    case
      when tg_op = 'INSERT' then 'create'
      when tg_op = 'UPDATE' and new.status = 'published' and old.status <> 'published' then 'publish'
      when tg_op = 'UPDATE' and new.status = 'archived'  and old.status <> 'archived'  then 'archive'
      when tg_op = 'UPDATE' then 'update'
      when tg_op = 'DELETE' then 'delete'
    end,
    to_jsonb(old),
    to_jsonb(new),
    coalesce(auth.uid(), (case when tg_op = 'DELETE' then old.author_uid else new.author_uid end))
  );
  return coalesce(new, old);
end;
$$;

drop trigger if exists qbank_drafts_log_trg on public.qbank_drafts;
create trigger qbank_drafts_log_trg
  after insert or update or delete on public.qbank_drafts
  for each row execute function public.qbank_drafts_log();

-- =============================================================================
-- 4. Convenience view — what the app should read
-- =============================================================================

-- The app should read all rows with status = 'published'. Drafts and reviews
-- stay invisible to end-users.
create or replace view public.qbank_published as
  select pool_id, id, payload, updated_at
  from public.qbank_drafts
  where status = 'published';

grant select on public.qbank_published to authenticated, anon;

-- =============================================================================
-- 5. Verification
-- =============================================================================

-- After running this migration, smoke-test:
--   select * from public.admin_users;          -- should be empty
--   select * from public.qbank_drafts;         -- should be empty
--   select * from public.qbank_audit;          -- should be empty
--   select * from public.qbank_published;      -- should be empty
--
-- Bootstrap your own admin row, then INSERT one test draft:
--   insert into public.qbank_drafts
--     (pool_id, id, status, payload, author_uid)
--   values
--     ('capitals', 'test_001', 'published',
--      '{"id":"test_001","question_en":"What is the capital of Test?","question_ar":"ما عاصمة اختبار؟","options":["Testopolis","A","B","C"],"correct_answer":"Testopolis","options_ar":["تستوبولس","أ","ب","ج"],"correct_answer_ar":"تستوبولس"}'::jsonb,
--      auth.uid());
--
-- Confirm appears in published view:
--   select * from public.qbank_published;
--
-- Confirm audit log captured the insert:
--   select * from public.qbank_audit order by at desc limit 5;
