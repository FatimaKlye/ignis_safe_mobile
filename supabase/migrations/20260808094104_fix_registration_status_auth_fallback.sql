-- Fixes the Sign Up -> Verify Email OTP flow.
--
-- Root cause: the check_email_status / cancel_pending_signup_email Edge
-- Functions queried auth.users via admin.from("auth.users"), which
-- PostgREST cannot resolve (it does not accept schema-qualified table
-- names in .from()). That call always failed, so the app could not tell
-- an already-registered/confirmed email apart from a brand-new one and
-- kept calling supabase.auth.signUp() again. Supabase's real behavior for
-- signUp() on an already-confirmed email is to return 200 without sending
-- any email and without throwing (anti-enumeration protection), so the
-- user was left waiting for an OTP that was never sent.
--
-- Fix: do the auth.users lookup inside Postgres (SECURITY DEFINER
-- functions can read the auth schema directly) instead of through
-- PostgREST, and use the real email_confirmed_at as the source of truth
-- when no profiles row exists yet.

create or replace function public.get_registration_status(p_email text)
returns text
language plpgsql
security definer
set search_path to 'public', 'auth'
as $function$
declare
  v_status       text;
  v_created_at   timestamptz;
  v_auth_id      uuid;
  v_confirmed_at timestamptz;
begin
  select registration_status, created_at
  into v_status, v_created_at
  from public.profiles
  where email = lower(trim(p_email))
  limit 1;

  if v_status is not null then
    -- Pending records older than 24 hours are treated as expired
    -- (allow the user to re-register cleanly)
    if v_status != 'completed'
       and v_created_at < now() - interval '24 hours' then
      return 'expired';
    end if;

    return v_status;
  end if;

  -- No profile row yet: fall back to the real Supabase Auth record so an
  -- account that already exists in auth.users is never misreported as
  -- "not_found".
  select id, email_confirmed_at
  into v_auth_id, v_confirmed_at
  from auth.users
  where lower(email) = lower(trim(p_email))
  limit 1;

  if v_auth_id is null then
    return 'not_found';
  end if;

  if v_confirmed_at is not null then
    return 'completed';
  end if;

  return 'pending_email_verification';
end;
$function$;

-- Used by the cancel_pending_signup_email Edge Function to look up the
-- auth user for a pending signup without going through PostgREST's
-- (unsupported) schema-qualified .from("auth.users").
create or replace function public.get_pending_signup_for_cleanup(p_email text)
returns table(user_id uuid, created_at timestamptz, is_completed boolean)
language plpgsql
security definer
set search_path to 'public', 'auth'
as $function$
begin
  return query
  select
    u.id,
    u.created_at,
    exists (
      select 1
      from public.profiles p
      where p.id = u.id
        and p.registration_status = 'completed'
    )
  from auth.users u
  where lower(u.email) = lower(trim(p_email))
  limit 1;
end;
$function$;

revoke all on function public.get_pending_signup_for_cleanup(text) from public;
grant execute on function public.get_pending_signup_for_cleanup(text) to service_role;
