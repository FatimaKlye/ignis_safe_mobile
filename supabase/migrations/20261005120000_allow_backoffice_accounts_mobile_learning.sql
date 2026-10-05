-- Personnel and Admin accounts use the mobile learner features with their
-- existing account and primary role. `add_mobile_learning_access` made
-- learner writes (assessment_attempts, module_progress, profiles) require an
-- opt-in `admin.mobile_access_enabled` flag that no account had, so every
-- Personnel/Admin assessment attempt was rejected by RLS (42501). Learner
-- access now follows the same rule as the mobile login gate: general mobile
-- users (no `admin` row) are always allowed, and Personnel/Admin accounts are
-- allowed while their account status is Active. `admin.role` is untouched.
begin;

create or replace function private.mobile_access_allowed()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    not exists (
      select 1 from public.admin a where a.admin_id = (select auth.uid())
    )
    or exists (
      select 1 from public.admin a
      where a.admin_id = (select auth.uid())
        and lower(trim(coalesce(a.status, ''))) = 'active'
    );
$$;

revoke all on function private.mobile_access_allowed() from public, anon;
grant execute on function private.mobile_access_allowed() to authenticated;

comment on column public.admin.mobile_access_enabled is
  'Deprecated: no longer enforced. Active Personnel/Admin accounts can always use mobile learning; see mobile_user_since for the Mobile User indicator.';

-- "Mobile User: Yes" indicator for Personnel/Admin accounts. This is a
-- secondary capability marker only: it never changes `role`, and these
-- accounts stay out of the general Mobile Users list (which excludes every
-- account with an `admin` row).
alter table public.admin
  add column if not exists mobile_user_since timestamptz;

comment on column public.admin.mobile_user_since is
  'When this Personnel/Admin account first used the mobile app. Not null = Mobile User: Yes. Does not affect role.';

-- Called by the mobile app after sign-in. Backoffice accounts cannot update
-- `admin` themselves, so this only stamps the caller's own row, only once,
-- and is a no-op for general mobile users.
create or replace function public.mark_mobile_app_user()
returns void
language sql
volatile
security definer
set search_path = ''
as $$
  update public.admin
  set mobile_user_since = now()
  where admin_id = (select auth.uid())
    and mobile_user_since is null
    and lower(trim(coalesce(status, ''))) = 'active';
$$;

revoke all on function public.mark_mobile_app_user() from public, anon;
grant execute on function public.mark_mobile_app_user() to authenticated;

-- Backfill accounts that already used the mobile app (Terms/Privacy consents
-- and learner activity are only recorded by the mobile app).
update public.admin as account
set mobile_user_since = first_use.first_seen
from (
  select activity.user_id, min(activity.seen_at) as first_seen
  from (
    select user_id, created_at as seen_at from public.user_consents
    union all
    select user_id, created_at from public.assessment_attempts
    union all
    select user_id, created_at from public.module_progress
    union all
    select user_id, created_at from public.simulation_attempts
  ) as activity
  group by activity.user_id
) as first_use
where first_use.user_id = account.admin_id
  and account.mobile_user_since is null;

commit;
