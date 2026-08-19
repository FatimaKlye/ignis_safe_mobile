-- The mobile profile menu's "Refresh & Check Updates" action re-fetches every
-- Supabase-driven screen and then compares the installed build with the latest
-- published mobile release. Refreshing data can never replace the installed
-- APK, so the release record lives here and the app points the user at the
-- real download instead.
create table if not exists public.mobile_app_versions (
  id uuid primary key default gen_random_uuid(),
  platform text not null default 'android',
  version text not null,
  build_number integer,
  release_notes text,
  release_notes_tl text,
  download_url text,
  is_mandatory boolean not null default false,
  is_active boolean not null default true,
  released_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint mobile_app_versions_platform_check
    check (platform in ('android', 'ios'))
);

comment on table public.mobile_app_versions is
  'Latest published IGNIS SAFE mobile builds. The app reads the newest active row for its platform to decide whether to show the update dialog.';
comment on column public.mobile_app_versions.version is
  'Dotted version as declared in pubspec.yaml, e.g. 1.0.0.';
comment on column public.mobile_app_versions.build_number is
  'Build number after the + in pubspec.yaml, e.g. 1. Used to break ties when the version string is unchanged.';
comment on column public.mobile_app_versions.download_url is
  'Where the user gets the new build (Play Store listing or APK link). Null shows the release info without a download action.';
comment on column public.mobile_app_versions.is_mandatory is
  'True keeps the update dialog non-dismissible.';

create index if not exists mobile_app_versions_platform_released_at_idx
  on public.mobile_app_versions (platform, released_at desc);

alter table public.mobile_app_versions enable row level security;

-- Mobile clients only ever read the published release, and they must be able
-- to do so on the login/splash path as well, so both roles get select access
-- limited to active rows.
drop policy if exists "Mobile app versions are readable"
  on public.mobile_app_versions;
create policy "Mobile app versions are readable"
  on public.mobile_app_versions
  for select
  to anon, authenticated
  using (is_active);

-- Seeds the build that is currently shipped (pubspec.yaml: version 1.0.0+1) so
-- the version check has a real baseline to compare against. Publishing a newer
-- release is a matter of inserting another row.
insert into public.mobile_app_versions (
  platform,
  version,
  build_number,
  release_notes,
  release_notes_tl
)
select
  'android',
  '1.0.0',
  1,
  'Initial IGNIS SAFE mobile release.',
  'Unang release ng IGNIS SAFE mobile.'
where not exists (
  select 1 from public.mobile_app_versions where platform = 'android'
);
