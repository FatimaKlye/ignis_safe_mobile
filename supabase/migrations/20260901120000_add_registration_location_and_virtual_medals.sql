-- Adds Dasmariñas-only learner locations and durable virtual achievements.
-- Existing profiles remain valid with a null location; new mobile signups send
-- all three location values together.

create table if not exists public.dasmarinas_barangays (
  name text primary key,
  display_order smallint not null unique check (display_order > 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

insert into public.dasmarinas_barangays (name, display_order)
values
  ('Burol', 1),
  ('Burol I', 2),
  ('Burol II', 3),
  ('Burol III', 4),
  ('Datu Esmael (Bago-a-ingud)', 5),
  ('Emmanuel Bergado I', 6),
  ('Emmanuel Bergado II', 7),
  ('Fatima I', 8),
  ('Fatima II', 9),
  ('Fatima III', 10),
  ('H-2', 11),
  ('Langkaan I', 12),
  ('Langkaan II', 13),
  ('Luzviminda I', 14),
  ('Luzviminda II', 15),
  ('Paliparan I', 16),
  ('Paliparan II', 17),
  ('Paliparan III', 18),
  ('Sabang', 19),
  ('Saint Peter I', 20),
  ('Saint Peter II', 21),
  ('Salawag', 22),
  ('Salitran I', 23),
  ('Salitran II', 24),
  ('Salitran III', 25),
  ('Salitran IV', 26),
  ('Sampaloc I', 27),
  ('Sampaloc II', 28),
  ('Sampaloc III', 29),
  ('Sampaloc IV', 30),
  ('Sampaloc V', 31),
  ('San Agustin I', 32),
  ('San Agustin II', 33),
  ('San Agustin III', 34),
  ('San Andres I', 35),
  ('San Andres II', 36),
  ('San Antonio De Padua I', 37),
  ('San Antonio De Padua II', 38),
  ('San Dionisio (Barangay 1)', 39),
  ('San Esteban (Barangay 4)', 40),
  ('San Francisco I', 41),
  ('San Francisco II', 42),
  ('San Isidro Labrador I', 43),
  ('San Isidro Labrador II', 44),
  ('San Jose', 45),
  ('San Juan (San Juan I)', 46),
  ('San Lorenzo Ruiz I', 47),
  ('San Lorenzo Ruiz II', 48),
  ('San Luis I', 49),
  ('San Luis II', 50),
  ('San Manuel I', 51),
  ('San Manuel II', 52),
  ('San Mateo', 53),
  ('San Miguel', 54),
  ('San Miguel II', 55),
  ('San Nicolas I', 56),
  ('San Nicolas II', 57),
  ('San Roque (Sta. Cristina II)', 58),
  ('San Simon (Barangay 7)', 59),
  ('Santa Cristina I', 60),
  ('Santa Cristina II', 61),
  ('Santa Cruz I', 62),
  ('Santa Cruz II', 63),
  ('Santa Fe', 64),
  ('Santa Lucia (San Juan II)', 65),
  ('Santa Maria (Barangay 20)', 66),
  ('Santo Cristo (Barangay 3)', 67),
  ('Santo Niño I', 68),
  ('Santo Niño II', 69),
  ('Victoria Reyes', 70),
  ('Zone I', 71),
  ('Zone I-B', 72),
  ('Zone II', 73),
  ('Zone III', 74),
  ('Zone IV', 75)
on conflict (name) do update
set display_order = excluded.display_order,
    is_active = true;

alter table public.dasmarinas_barangays enable row level security;

revoke all on table public.dasmarinas_barangays from anon, authenticated;
grant select on table public.dasmarinas_barangays to anon, authenticated;
grant insert, update, delete on table public.dasmarinas_barangays to authenticated;

drop policy if exists dasmarinas_barangays_read on public.dasmarinas_barangays;
create policy dasmarinas_barangays_read
on public.dasmarinas_barangays
for select
to anon, authenticated
using (true);

drop policy if exists dasmarinas_barangays_admin_insert on public.dasmarinas_barangays;
create policy dasmarinas_barangays_admin_insert
on public.dasmarinas_barangays
for insert
to authenticated
with check ((select public.is_admin_user()));

drop policy if exists dasmarinas_barangays_admin_update on public.dasmarinas_barangays;
create policy dasmarinas_barangays_admin_update
on public.dasmarinas_barangays
for update
to authenticated
using ((select public.is_admin_user()))
with check ((select public.is_admin_user()));

drop policy if exists dasmarinas_barangays_admin_delete on public.dasmarinas_barangays;
create policy dasmarinas_barangays_admin_delete
on public.dasmarinas_barangays
for delete
to authenticated
using ((select public.is_admin_user()));

alter table public.profiles
  add column if not exists city text,
  add column if not exists province text,
  add column if not exists barangay text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_barangay_fkey'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_barangay_fkey
      foreign key (barangay)
      references public.dasmarinas_barangays(name)
      on update cascade;
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_dasmarinas_location_complete'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_dasmarinas_location_complete
      check (
        (city is null and province is null and barangay is null)
        or (
          city = 'Dasmariñas City'
          and province = 'Cavite'
          and barangay is not null
        )
      );
  end if;
end
$$;

create index if not exists profiles_barangay_idx
  on public.profiles (barangay)
  where barangay is not null;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  safe_email text;
  lang text;
  profile_city text;
  profile_province text;
  profile_barangay text;
begin
  safe_email := nullif(lower(coalesce(new.email, '')), '');
  lang := coalesce(new.raw_user_meta_data->>'app_language_code', 'en');

  if lang not in ('en', 'tl') then
    lang := 'en';
  end if;

  if new.raw_user_meta_data->>'city' = 'Dasmariñas City'
     and new.raw_user_meta_data->>'province' = 'Cavite'
     and exists (
       select 1
       from public.dasmarinas_barangays b
       where b.name = new.raw_user_meta_data->>'barangay'
         and b.is_active
     ) then
    profile_city := 'Dasmariñas City';
    profile_province := 'Cavite';
    profile_barangay := new.raw_user_meta_data->>'barangay';
  end if;

  insert into public.profiles (
    id,
    email,
    first_name,
    last_name,
    app_language_code,
    city,
    province,
    barangay,
    terms_accepted,
    terms_accepted_at,
    registration_status,
    updated_at
  )
  values (
    new.id,
    safe_email,
    new.raw_user_meta_data->>'first_name',
    new.raw_user_meta_data->>'last_name',
    lang,
    profile_city,
    profile_province,
    profile_barangay,
    false,
    null,
    'pending_email_verification',
    now()
  )
  on conflict (id) do update
  set
    email = coalesce(excluded.email, public.profiles.email),
    first_name = coalesce(excluded.first_name, public.profiles.first_name),
    last_name = coalesce(excluded.last_name, public.profiles.last_name),
    app_language_code = coalesce(excluded.app_language_code, public.profiles.app_language_code),
    city = coalesce(excluded.city, public.profiles.city),
    province = coalesce(excluded.province, public.profiles.province),
    barangay = coalesce(excluded.barangay, public.profiles.barangay),
    updated_at = now();

  return new;
end;
$function$;

create table if not exists public.medal_definitions (
  code text primary key,
  module_no integer unique check (module_no between 1 and 5),
  title text not null,
  description text not null,
  icon_key text not null,
  display_order smallint not null unique check (display_order > 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint medal_definitions_code_check
    check (code = 'all_modules' or code = 'module_' || module_no::text)
);

insert into public.medal_definitions (
  code,
  module_no,
  title,
  description,
  icon_key,
  display_order
)
values
  ('module_1', 1, 'Extinguisher Ready', 'Completed Fire Extinguisher training.', 'fire_extinguisher', 1),
  ('module_2', 2, 'Escape Prepared', 'Completed House Fire Escape training.', 'home', 2),
  ('module_3', 3, 'Electrical Aware', 'Completed Electrical Fire training.', 'electrical_services', 3),
  ('module_4', 4, 'Kitchen Guardian', 'Completed Kitchen Fire training.', 'soup_kitchen', 4),
  ('module_5', 5, 'Building Responder', 'Completed Tenement Fire training.', 'apartment', 5),
  ('all_modules', null, 'IGNIS SAFE Champion', 'Completed all five IGNIS SAFE training modules.', 'local_fire_department', 6)
on conflict (code) do update
set module_no = excluded.module_no,
    title = excluded.title,
    description = excluded.description,
    icon_key = excluded.icon_key,
    display_order = excluded.display_order,
    is_active = true,
    updated_at = now();

alter table public.medal_definitions enable row level security;

revoke all on table public.medal_definitions from anon, authenticated;
grant select on table public.medal_definitions to authenticated;

drop policy if exists medal_definitions_read on public.medal_definitions;
create policy medal_definitions_read
on public.medal_definitions
for select
to authenticated
using (is_active);

create table if not exists public.user_medals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  medal_code text not null references public.medal_definitions(code),
  earned_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint user_medals_user_medal_unique unique (user_id, medal_code)
);

create index if not exists user_medals_user_id_idx
  on public.user_medals (user_id);

create index if not exists user_medals_medal_code_idx
  on public.user_medals (medal_code);

alter table public.user_medals enable row level security;

revoke all on table public.user_medals from anon, authenticated;
grant select on table public.user_medals to authenticated;

drop policy if exists user_medals_select_own_or_admin on public.user_medals;
create policy user_medals_select_own_or_admin
on public.user_medals
for select
to authenticated
using (
  (select auth.uid()) = user_id
  or (select public.is_admin_user())
);

create schema if not exists private;

create or replace function private.sync_virtual_medals_for_user(target_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if target_user_id is null then
    return;
  end if;

  insert into public.user_medals (user_id, medal_code, earned_at)
  select
    target_user_id,
    'module_' || m.module_no::text,
    mp.post_test_completed_at
  from public.module_progress mp
  join public.modules m on m.id = mp.module_id
  where mp.user_id = target_user_id
    and m.module_no between 1 and 5
    and mp.pre_test_completed_at is not null
    and mp.pre_test_attempt_id is not null
    and mp.pre_test_score is not null
    and exists (
      select 1
      from public.assessment_attempts pre_attempt
      where pre_attempt.id = mp.pre_test_attempt_id
        and pre_attempt.user_id = target_user_id
        and pre_attempt.status = 'submitted'
        and pre_attempt.submitted_at is not null
        and pre_attempt.score is not null
    )
    and mp.learning_material_completed_at is not null
    and mp.learning_material_read_status is true
    and mp.post_test_completed_at is not null
    and mp.post_test_attempt_id is not null
    and mp.post_test_score is not null
    and exists (
      select 1
      from public.assessment_attempts post_attempt
      where post_attempt.id = mp.post_test_attempt_id
        and post_attempt.user_id = target_user_id
        and post_attempt.status = 'submitted'
        and post_attempt.submitted_at is not null
        and post_attempt.score is not null
    )
  on conflict (user_id, medal_code) do nothing;

  if (
    select count(*) = 5
    from public.user_medals um
    where um.user_id = target_user_id
      and um.medal_code in (
        'module_1',
        'module_2',
        'module_3',
        'module_4',
        'module_5'
      )
  ) then
    insert into public.user_medals (user_id, medal_code, earned_at)
    select
      target_user_id,
      'all_modules',
      max(um.earned_at)
    from public.user_medals um
    where um.user_id = target_user_id
      and um.medal_code like 'module_%'
    on conflict (user_id, medal_code) do nothing;
  end if;
end;
$function$;

revoke all on function private.sync_virtual_medals_for_user(uuid)
  from public, anon, authenticated;

create or replace function public.sync_my_virtual_medals()
returns table (
  medal_code text,
  module_no integer,
  title text,
  description text,
  earned_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  caller_id uuid;
begin
  caller_id := auth.uid();
  if caller_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  perform private.sync_virtual_medals_for_user(caller_id);

  return query
  select
    um.medal_code,
    md.module_no,
    md.title,
    md.description,
    um.earned_at
  from public.user_medals um
  join public.medal_definitions md on md.code = um.medal_code
  where um.user_id = caller_id
    and md.is_active
  order by md.display_order;
end;
$function$;

revoke all on function public.sync_my_virtual_medals()
  from public, anon;
grant execute on function public.sync_my_virtual_medals()
  to authenticated;

create or replace function public.award_virtual_medals_after_progress()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  perform private.sync_virtual_medals_for_user(new.user_id);
  return new;
end;
$function$;

revoke all on function public.award_virtual_medals_after_progress()
  from public, anon, authenticated;

drop trigger if exists award_virtual_medals_on_progress
  on public.module_progress;
create trigger award_virtual_medals_on_progress
after insert or update of
  pre_test_completed_at,
  pre_test_attempt_id,
  pre_test_score,
  learning_material_completed_at,
  learning_material_read_status,
  post_test_completed_at,
  post_test_attempt_id,
  post_test_score
on public.module_progress
for each row
execute function public.award_virtual_medals_after_progress();

-- Backfill existing valid completion records without changing progress.
do $backfill$
declare
  learner record;
begin
  for learner in
    select distinct mp.user_id
    from public.module_progress mp
  loop
    perform private.sync_virtual_medals_for_user(learner.user_id);
  end loop;
end
$backfill$;

comment on table public.dasmarinas_barangays is
  'Canonical barangay choices for Dasmariñas City mobile learner registration.';
comment on table public.user_medals is
  'Durable virtual medals awarded from validated IGNIS SAFE module completion.';
comment on function public.sync_my_virtual_medals() is
  'Validates the signed-in learner module progress, safely persists earned medals, and returns their earned collection.';
