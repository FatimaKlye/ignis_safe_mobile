create or replace function public.get_my_module_progress_overview()
returns table (
  module_no integer,
  pre_test_completed boolean,
  can_open_learning boolean,
  learning_completed boolean,
  can_open_post_test boolean,
  post_test_completed boolean
)
language sql
stable
security invoker
set search_path = ''
as $function$
  with module_state as (
    select
      m.module_no,
      mp.pre_test_completed_at,
      mp.pre_test_attempt_id,
      mp.pre_test_score,
      mp.learning_material_completed_at,
      mp.learning_material_read_status,
      mp.post_test_completed_at,
      mp.post_test_attempt_id,
      mp.post_test_score,
      pre_attempt.id as submitted_pre_attempt_id,
      post_attempt.id as submitted_post_attempt_id
    from public.modules as m
    left join public.assessments as pre_assessment
      on pre_assessment.module_id = m.id
     and pre_assessment.type::text = 'pre'
    left join public.assessments as post_assessment
      on post_assessment.module_id = m.id
     and post_assessment.type::text = 'post'
    left join public.module_progress as mp
      on mp.module_id = m.id
     and mp.user_id = (select auth.uid())
    left join public.assessment_attempts as pre_attempt
      on pre_attempt.assessment_id = pre_assessment.id
     and pre_attempt.user_id = (select auth.uid())
     and pre_attempt.status = 'submitted'
     and pre_attempt.submitted_at is not null
     and pre_attempt.score is not null
    left join public.assessment_attempts as post_attempt
      on post_attempt.assessment_id = post_assessment.id
     and post_attempt.user_id = (select auth.uid())
     and post_attempt.status = 'submitted'
     and post_attempt.submitted_at is not null
     and post_attempt.score is not null
    where m.module_no between 1 and 5
  ),
  validated as (
    select
      module_state.*,
      (
        pre_test_completed_at is not null
        and pre_test_attempt_id is not null
        and pre_test_score is not null
        and submitted_pre_attempt_id is not null
        and pre_test_attempt_id = submitted_pre_attempt_id
      ) as valid_pre_test,
      (
        learning_material_completed_at is not null
        and learning_material_read_status is true
      ) as valid_learning,
      (
        post_test_completed_at is not null
        and post_test_attempt_id is not null
        and post_test_score is not null
        and submitted_post_attempt_id is not null
        and post_test_attempt_id = submitted_post_attempt_id
      ) as valid_post_test
    from module_state
  )
  select
    module_no,
    (
      valid_pre_test
      or submitted_pre_attempt_id is not null
      or (
        pre_test_completed_at is not null
        and pre_test_attempt_id is not null
        and pre_test_score is not null
      )
    ) as pre_test_completed,
    valid_pre_test as can_open_learning,
    valid_learning as learning_completed,
    (
      valid_pre_test
      and valid_learning
      and not valid_post_test
    ) as can_open_post_test,
    valid_post_test as post_test_completed
  from validated
  order by module_no;
$function$;

revoke all on function public.get_my_module_progress_overview() from public;
revoke all on function public.get_my_module_progress_overview() from anon;
grant execute on function public.get_my_module_progress_overview() to authenticated;

comment on function public.get_my_module_progress_overview() is
  'Returns the signed-in user''s validated progress for mobile modules 1-5 in one request.';
