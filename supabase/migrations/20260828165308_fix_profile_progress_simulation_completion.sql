-- Adds Andrei's public portfolio metadata and prevents more than one completed
-- simulation-attempt record for the same learner and module.

alter table public.about_us_team_members
  add column if not exists portfolio_url text;

comment on column public.about_us_team_members.portfolio_url is
  'Optional public portfolio website shown in the mobile About Us profile.';

update public.about_us_team_members
set
  role_en = 'Project Manager',
  role_tl = 'Project Manager',
  portfolio_url = 'https://andreiquias.vercel.app/',
  updated_at = now()
where lower(email) = 'andreicarisma24@gmail.com'
   or lower(full_name) = 'andrei c. quias';

create unique index if not exists simulation_attempts_one_done_per_user_module
  on public.simulation_attempts (user_id, module_id)
  where status = 'done';
