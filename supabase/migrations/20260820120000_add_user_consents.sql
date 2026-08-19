-- Versioned consent history for the IGNIS SAFE mobile app.
--
-- `profiles.terms_accepted` / `profiles.terms_accepted_at` are kept for
-- backwards compatibility with the admin dashboard, but the authoritative
-- record of what a learner agreed to (which document, which version, in
-- which language, and when) now lives here so that consent can be proven
-- and re-requested when a document materially changes, as expected under
-- the Data Privacy Act of 2012 (RA 10173).

create table if not exists public.user_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  document_type text not null,
  document_version text not null,
  accepted boolean not null default true,
  accepted_at timestamptz not null default now(),
  withdrawn_at timestamptz,
  language text not null default 'en',
  created_at timestamptz not null default now(),
  constraint user_consents_document_type_check
    check (document_type in ('terms', 'privacy', 'research')),
  constraint user_consents_language_check
    check (language in ('en', 'tl')),
  constraint user_consents_withdrawn_after_accepted
    check (withdrawn_at is null or withdrawn_at >= accepted_at)
);

comment on table public.user_consents is
  'Append-only consent history (Terms, Privacy Notice, optional research participation). Rows are never edited except to set withdrawn_at.';

create index if not exists user_consents_user_id_idx
  on public.user_consents (user_id);

create index if not exists user_consents_lookup_idx
  on public.user_consents (user_id, document_type, document_version);

-- One live acceptance per (user, document, version). Withdrawing releases the
-- slot so the same document can be consented to again later.
create unique index if not exists user_consents_active_unique
  on public.user_consents (user_id, document_type, document_version)
  where withdrawn_at is null and accepted;

-- Consent records are evidence: once written, only withdrawal may change them.
create or replace function public.enforce_user_consent_immutability()
returns trigger
language plpgsql
as $$
begin
  if new.id is distinct from old.id
     or new.user_id is distinct from old.user_id
     or new.document_type is distinct from old.document_type
     or new.document_version is distinct from old.document_version
     or new.accepted is distinct from old.accepted
     or new.accepted_at is distinct from old.accepted_at
     or new.language is distinct from old.language
     or new.created_at is distinct from old.created_at then
    raise exception
      'Consent records are immutable; only withdrawn_at may be set.'
      using errcode = 'check_violation';
  end if;

  if old.withdrawn_at is not null
     and new.withdrawn_at is distinct from old.withdrawn_at then
    raise exception
      'A withdrawn consent record cannot be changed.'
      using errcode = 'check_violation';
  end if;

  return new;
end;
$$;

drop trigger if exists user_consents_immutability on public.user_consents;

create trigger user_consents_immutability
  before update on public.user_consents
  for each row
  execute function public.enforce_user_consent_immutability();

alter table public.user_consents enable row level security;

-- A learner sees only their own consent history; back-office admins may read
-- all of it for compliance reporting, matching the profiles policy shape.
drop policy if exists user_consents_select_own_or_admin on public.user_consents;
create policy user_consents_select_own_or_admin
  on public.user_consents
  for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or (select private.current_backoffice_role()) = 'admin'
  );

drop policy if exists user_consents_insert_own on public.user_consents;
create policy user_consents_insert_own
  on public.user_consents
  for insert
  to authenticated
  with check (user_id = (select auth.uid()));

-- Update exists only so a user can withdraw; the trigger above blocks
-- everything else.
drop policy if exists user_consents_update_own on public.user_consents;
create policy user_consents_update_own
  on public.user_consents
  for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- No delete policy is defined on purpose: history must be preserved.
revoke delete on public.user_consents from authenticated;
revoke all on public.user_consents from anon;

-- Preserve the acceptances that were only recorded as profiles.terms_accepted
-- before this table existed. They are stamped as the legacy document version
-- so the app will still ask for the current Terms and Privacy Notice.
insert into public.user_consents (
  user_id, document_type, document_version, accepted, accepted_at, language
)
select
  p.id,
  'terms',
  'legacy-1.0',
  true,
  coalesce(p.terms_accepted_at, p.updated_at, p.created_at, now()),
  case when p.app_language_code = 'tl' then 'tl' else 'en' end
from public.profiles p
where p.terms_accepted is true
on conflict do nothing;
