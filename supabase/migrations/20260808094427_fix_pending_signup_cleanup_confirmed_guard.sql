-- The previous version of get_pending_signup_for_cleanup only treated an
-- account as "protected from deletion" if it had a public.profiles row
-- with registration_status = 'completed'. That missed accounts that are
-- genuinely confirmed in auth.users (real email_confirmed_at) but have no
-- profiles row - the exact same data gap the whole OTP bug was about. Add
-- the same auth.users.email_confirmed_at fallback used in
-- get_registration_status so cancel_pending_signup_email can never delete
-- an already-confirmed account again.

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
    (
      u.email_confirmed_at is not null
      or exists (
        select 1
        from public.profiles p
        where p.id = u.id
          and p.registration_status = 'completed'
      )
    )
  from auth.users u
  where lower(u.email) = lower(trim(p_email))
  limit 1;
end;
$function$;
