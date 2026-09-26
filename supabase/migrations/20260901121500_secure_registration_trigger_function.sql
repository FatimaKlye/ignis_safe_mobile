-- Trigger functions are internal implementation details and must not be
-- callable through the exposed Data API.
revoke all on function public.handle_new_user()
  from public, anon, authenticated;
