-- Migration: 2026-05-18b — Feature flags for smart admin
--
-- Lets the admin toggle individual app sections / features on or off at
-- runtime without a redeploy. The app reads `feature_flags` once at boot
-- and on focus-resume; sections check `featureEnabled(key)` before
-- rendering their tile / route.
--
-- Apply: paste into Supabase SQL editor → Run. Migration is idempotent.

create table if not exists public.feature_flags (
  key text primary key,
  enabled boolean not null default true,
  label_en text not null,
  label_ar text not null,
  category text not null default 'feature' check (category in ('feature','section','game','admin')),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);

alter table public.feature_flags enable row level security;

-- Read: anyone can read flags (anon + auth). The app needs them at boot.
drop policy if exists feature_flags_read on public.feature_flags;
create policy feature_flags_read on public.feature_flags
  for select using (true);

-- Write: only admins.
drop policy if exists feature_flags_write on public.feature_flags;
create policy feature_flags_write on public.feature_flags
  for all using (
    auth.role() = 'authenticated' and
    exists (select 1 from public.admin_users a where a.uid = auth.uid())
  ) with check (
    auth.role() = 'authenticated' and
    exists (select 1 from public.admin_users a where a.uid = auth.uid())
  );

-- Auto-touch updated_at + updated_by on every change.
create or replace function public.feature_flags_touch() returns trigger as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end;
$$ language plpgsql;

drop trigger if exists feature_flags_touch_trg on public.feature_flags;
create trigger feature_flags_touch_trg
  before update on public.feature_flags
  for each row execute function public.feature_flags_touch();

-- Seed the canonical set of toggleable sections. These match the
-- AppRoutes constants in lib/core/router/app_router.dart so the admin
-- knows what they control. Re-running INSERT is a no-op thanks to ON
-- CONFLICT.
insert into public.feature_flags (key, label_en, label_ar, category) values
  -- Learn category
  ('capitals',          'Capitals Quiz',          'اختبار العواصم',       'section'),
  ('flags',             'Flags Quiz',             'اختبار الأعلام',       'section'),
  ('maps',              'Maps',                   'الخرائط',              'section'),
  ('logos',             'Logos',                  'الشعارات',             'section'),
  ('sciences',          'Sciences',               'العلوم',               'section'),
  ('math',              'Math',                   'الرياضيات',            'section'),
  ('madrasati',         'Madrasati (curriculum)', 'مدرستي',               'section'),
  -- Islamic category
  ('quran',             'Quran (short surahs)',   'القرآن الكريم',        'section'),
  ('hadith',            'Hadith memorization',    'حفظ الأحاديث',         'section'),
  ('hadith_quiz',       'Hadith Quiz',            'اختبار الحديث',        'section'),
  ('athkar',            'Athkar',                 'الأذكار',              'section'),
  ('dua',               'Du''a memorization',     'حفظ الأدعية',          'section'),
  ('asma_ul_husna',     '99 Names of Allah',      'أسماء الله الحسنى',   'section'),
  ('tajweed_basics',    'Tajweed basics',         'أساسيات التجويد',      'section'),
  ('prophet_stories',   'Prophet Stories',        'قصص الأنبياء',         'section'),
  ('salah_steps',       'Salah steps',            'خطوات الصلاة',         'section'),
  ('wudu_steps',        'Wudu steps',             'خطوات الوضوء',         'section'),
  -- Brain Boost / IQ
  ('iq',                'IQ Challenge',           'تحدي الذكاء',          'section'),
  ('brain_boost',       'Brain Boost',            'تنمية الذكاء',         'section'),
  ('daily_challenge',   'Daily Challenge',        'تحدي اليوم',           'section'),
  -- Engagement
  ('plus',              'Aziz Academy Plus',      'أكاديمية عزيز Plus',   'feature'),
  ('ads_parent_screens','Ads on parent screens',  'إعلانات صفحات الأهل',  'feature'),
  ('cloud_tts',         'Cloud Neural TTS',       'صوت ذكي عبر السحابة', 'feature')
on conflict (key) do nothing;

-- View for app boot: returns only the enabled keys (smaller payload).
create or replace view public.feature_flags_enabled as
  select key from public.feature_flags where enabled = true;

grant select on public.feature_flags_enabled to anon, authenticated;
grant select on public.feature_flags to anon, authenticated;

-- Verify
-- select * from public.feature_flags order by category, key;
