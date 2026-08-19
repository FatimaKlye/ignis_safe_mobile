-- Server-side enforcement of the Mobile > Profile > Feedback rate limit:
-- each authenticated account may submit at most 1 row to
-- public.user_feedback every 72 hours, based on that account's own latest
-- `created_at`. Enforced with a BEFORE INSERT trigger so it cannot be
-- bypassed by repeated taps, app restarts, logout/login, or direct API
-- calls that skip the Flutter app entirely. get_feedback_cooldown() exposes
-- the same real data to the app so it can show/disable the Submit button
-- without needing a failed insert first.

create or replace function public.enforce_user_feedback_rate_limit()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_latest_at timestamptz;
  v_next_allowed_at timestamptz;
begin
  select max(created_at)
    into v_latest_at
    from public.user_feedback
    where user_id = new.user_id;

  if v_latest_at is not null then
    v_next_allowed_at := v_latest_at + interval '72 hours';

    if now() < v_next_allowed_at then
      raise exception
        'You can submit feedback again on %.', v_next_allowed_at
        using
          errcode = 'P0001',
          hint = 'feedback_rate_limited',
          detail = v_next_allowed_at::text;
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists user_feedback_rate_limit on public.user_feedback;
create trigger user_feedback_rate_limit
  before insert on public.user_feedback
  for each row
  execute function public.enforce_user_feedback_rate_limit();

-- Returns the calling account's real cooldown state, computed from the
-- latest row it can see in public.user_feedback (its own rows only, per the
-- existing select policy). No state is cached or hardcoded client-side.
create or replace function public.get_feedback_cooldown()
returns table (
  is_limited boolean,
  next_allowed_at timestamptz,
  latest_feedback_at timestamptz
)
language sql
stable
set search_path = public
as $$
  select
    coalesce(now() < max(created_at) + interval '72 hours', false) as is_limited,
    max(created_at) + interval '72 hours' as next_allowed_at,
    max(created_at) as latest_feedback_at
  from public.user_feedback
  where user_id = (select auth.uid());
$$;

grant execute on function public.get_feedback_cooldown() to authenticated;
