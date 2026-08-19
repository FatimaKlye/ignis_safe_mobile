-- In-app feedback submitted from Mobile > Profile > Account & Support.
--
-- Each row is a single learner's star rating (1-5) plus an optional
-- recommendation/comment. Append-only: once submitted, feedback is not
-- editable from the app, so no update policy is granted.

create table if not exists public.user_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  rating smallint not null,
  comment text,
  created_at timestamptz not null default now(),
  constraint user_feedback_rating_range check (rating between 1 and 5)
);

comment on table public.user_feedback is
  'Append-only star rating + optional comment submitted from the mobile app Feedback form.';

create index if not exists user_feedback_user_id_idx
  on public.user_feedback (user_id);

create index if not exists user_feedback_created_at_idx
  on public.user_feedback (created_at desc);

alter table public.user_feedback enable row level security;

-- A learner sees only their own feedback; back-office admins may read all of
-- it, matching the user_consents policy shape.
drop policy if exists user_feedback_select_own_or_admin on public.user_feedback;
create policy user_feedback_select_own_or_admin
  on public.user_feedback
  for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or (select private.current_backoffice_role()) = 'admin'
  );

drop policy if exists user_feedback_insert_own on public.user_feedback;
create policy user_feedback_insert_own
  on public.user_feedback
  for insert
  to authenticated
  with check (user_id = (select auth.uid()));

-- No update/delete policy is defined on purpose: submitted feedback is
-- immutable from the app.
revoke update, delete on public.user_feedback from authenticated;
revoke all on public.user_feedback from anon;
