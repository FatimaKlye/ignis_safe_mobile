-- Restore the original shared sign-in behavior: any authenticated account,
-- including personnel accounts created through the website, may use mobile.
create or replace function public.is_mobile_learner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null;
$$;

revoke all on function public.is_mobile_learner() from public;
revoke all on function public.is_mobile_learner() from anon;
grant execute on function public.is_mobile_learner() to authenticated;

-- Password recovery is shared as well, so personnel Auth accounts are
-- recognized by the mobile forgot-password flow.
create or replace function public.account_exists_for_password_reset(p_email text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_email text := lower(trim(p_email));
begin
  if normalized_email is null or normalized_email = '' then
    return false;
  end if;

  return exists (
    select 1
    from auth.users u
    where lower(u.email) = normalized_email
      and u.deleted_at is null
  )
  or exists (
    select 1
    from public.profiles p
    where lower(p.email) = normalized_email
  );
end;
$$;
