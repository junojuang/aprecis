-- Adds the editorial blueprint blob: highlights, ELI5 metaphor, core findings,
-- timeline checkpoints, viz card specs, complete quote/tease. Rendered by the
-- iOS DailyLoopView via DailyLoopContent.init(deck:blueprint:).
alter table cards
  add column if not exists blueprint jsonb;
