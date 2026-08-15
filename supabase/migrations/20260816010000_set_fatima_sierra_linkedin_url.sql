-- Fatima's About Us developer profile shipped without a LinkedIn link, so the
-- modal fell back to the "pending" state. Point the LinkedIn action at her real
-- profile. Matched on full_name so no generated id is baked into the migration.
update public.about_us_team_members
   set linkedin_url = 'https://www.linkedin.com/in/fatima-klye-sierra-902060288/'
 where full_name = 'FATIMA KLYE M. SIERRA';
