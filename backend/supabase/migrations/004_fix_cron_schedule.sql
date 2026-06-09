-- Fix invalid cron schedule: '*/90 * * * *' never fires (minute field is 0–59).
-- Switch cron-ingest to run every 3 hours (at minute 0).

select cron.unschedule('cron-ingest');

select cron.schedule(
  'cron-ingest',
  '0 */3 * * *',
  $$select net.http_post(
    url := current_setting('app.supabase_url') || '/functions/v1/cron-ingest',
    headers := jsonb_build_object('Authorization', 'Bearer ' || current_setting('app.service_role_key'))
  )$$
);
