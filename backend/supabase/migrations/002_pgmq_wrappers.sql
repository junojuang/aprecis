-- Public wrappers so PostgREST (.rpc()) can call pgmq functions

CREATE OR REPLACE FUNCTION public.pgmq_send_batch(queue_name text, messages jsonb[])
RETURNS SETOF bigint LANGUAGE sql SECURITY DEFINER AS $$
  SELECT * FROM pgmq.send_batch(queue_name, messages);
$$;

CREATE OR REPLACE FUNCTION public.pgmq_read(queue_name text, vt integer, qty integer)
RETURNS TABLE(msg_id bigint, read_ct integer, enqueued_at timestamptz, vt timestamptz, message jsonb)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT msg_id, read_ct, enqueued_at, vt, message FROM pgmq.read(queue_name, vt, qty);
$$;

CREATE OR REPLACE FUNCTION public.pgmq_delete(queue_name text, msg_id bigint)
RETURNS boolean LANGUAGE sql SECURITY DEFINER AS $$
  SELECT pgmq.delete(queue_name, msg_id);
$$;
