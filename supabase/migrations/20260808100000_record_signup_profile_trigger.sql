-- public.handle_new_user() / on_auth_user_created already exist on the live
-- project but were created ad hoc (outside migration tracking) at some
-- point before this fix. Recorded here for repo/production parity so a
-- fresh `supabase db reset` reproduces the same signup behavior: every new
-- auth.users row immediately gets a public.profiles row with
-- registration_status = 'pending_email_verification', which
-- get_registration_status()/check_email_status rely on.

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  safe_email text;
  lang text;
begin
  safe_email := nullif(lower(coalesce(new.email, '')), '');
  lang := coalesce(new.raw_user_meta_data->>'app_language_code', 'en');

  if lang not in ('en', 'tl') then
    lang := 'en';
  end if;

  insert into public.profiles (
    id,
    email,
    first_name,
    last_name,
    app_language_code,
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
    updated_at = now();

  return new;
end;
$function$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
