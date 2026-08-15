-- The mobile About Us developer profile modal shows an Email and a LinkedIn
-- action. The LinkedIn link had no home in the schema, so it is added here to
-- keep every piece of developer content sourced from the database.
alter table public.about_us_team_members
  add column if not exists linkedin_url text;

comment on column public.about_us_team_members.linkedin_url is
  'Full LinkedIn profile URL (https://www.linkedin.com/in/...). Null hides the LinkedIn action in the mobile profile modal.';

-- Button labels for the redesigned developer profile modal.
insert into public.about_us_ui_texts (key, text_en, text_tl)
values
  ('member_email_action', 'Email', 'Email'),
  ('member_linkedin_action', 'LinkedIn', 'LinkedIn')
on conflict (key) do update
  set text_en = excluded.text_en,
      text_tl = excluded.text_tl;
