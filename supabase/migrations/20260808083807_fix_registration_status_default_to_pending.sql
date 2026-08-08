-- Fix: profiles.registration_status defaulted to 'completed', which meant
-- an abandoned/unverified signup (auth.users row created before OTP entry)
-- was immediately treated as a fully registered account by check_email_status
-- and protected from cleanup by cancel_pending_signup_email.
-- Correct starting state is 'pending_email_verification'; registration_status
-- is only ever set to 'completed' after OTP verification succeeds
-- (see verifyemail.dart upsert on successful verifyOTP).

ALTER TABLE public.profiles
  ALTER COLUMN registration_status SET DEFAULT 'pending_email_verification';

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
