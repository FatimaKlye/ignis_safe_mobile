-- Keep personnel/admin identities out of the learner-facing mobile app.
-- `public.admin` is the authoritative back-office account registry; unlike
-- auth user metadata, mobile clients cannot edit it themselves.

create or replace function public.is_mobile_learner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and not exists (
      select 1
      from public.admin as backoffice_account
      where backoffice_account.admin_id = auth.uid()
    );
$$;

revoke all on function public.is_mobile_learner() from public;
revoke all on function public.is_mobile_learner() from anon;
grant execute on function public.is_mobile_learner() to authenticated;

-- The mobile forgot-password screen may only acknowledge learner accounts.
-- Check the canonical admin registry by both linked ID and normalized email so
-- older back-office records are also excluded.
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
    from auth.users as auth_user
    where lower(auth_user.email) = normalized_email
      and not exists (
        select 1
        from public.admin as backoffice_account
        where backoffice_account.admin_id = auth_user.id
           or lower(backoffice_account.email) = normalized_email
      )
  );
end;
$$;
