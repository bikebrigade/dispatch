-- Run by scripts/restore_staging_db on staging right after it loads a copy of
-- production, before staging starts again. This is not anonymization: names,
-- addresses and history stay real. It removes what messages are sent *to*, so
-- staging can't text or Slack anyone even if a code guard fails:
--
--   * Only users whose email is in :allowed_emails keep a phone number and
--     dispatcher access (the SMS guard trusts dispatcher phones). Their rider
--     profiles keep real phones too.
--   * Every other rider gets a unique fake 555 phone; recipient phones become
--     one fake number.
--   * Program Slack channels are cleared and delivery summaries turned off
--     (delivery notes then fall back to the configured #api-playground).
--
-- It ends by checking all of that and raises (rolling everything back) if
-- anything real is left, so the restore script stops with staging still down.
--
-- Usage: psql "$URL" -v allowed_emails='me@example.com,you@example.com' -f staging_scrub.sql

\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE allowed_users ON COMMIT DROP AS
SELECT id, rider_id
FROM users
WHERE lower(email) = ANY (regexp_split_to_array(lower(trim(:'allowed_emails')), '\s*,\s*'));

CREATE TEMP TABLE allowed_riders ON COMMIT DROP AS
SELECT rider_id AS id FROM allowed_users WHERE rider_id IS NOT NULL;

-- Users: only allowlisted ones keep a phone, and they're the only dispatchers
UPDATE users
SET phone = NULL, is_dispatcher = false
WHERE id NOT IN (SELECT id FROM allowed_users);

UPDATE users SET is_dispatcher = true WHERE id IN (SELECT id FROM allowed_users);

-- Riders: unique fake numbers in the 555 exchange (riders.phone is unique),
-- e.g. +14165550042. Numbered by position, not ID, so they never collide;
-- six area codes give room for 60,000 riders.
DO $$
BEGIN
  IF (SELECT count(*) FROM riders WHERE id NOT IN (SELECT id FROM allowed_riders)) > 60000 THEN
    RAISE EXCEPTION 'More than 60,000 riders to scrub; add area codes to staging_scrub.sql';
  END IF;
END
$$;

WITH numbered AS (
  SELECT id, row_number() OVER (ORDER BY id) - 1 AS n
  FROM riders
  WHERE id NOT IN (SELECT id FROM allowed_riders)
)
UPDATE riders
SET phone = '+1'
  || (ARRAY['416', '647', '437', '289', '905', '365'])[numbered.n / 10000 + 1]
  || '555'
  || lpad((numbered.n % 10000)::text, 4, '0')
FROM numbered
WHERE riders.id = numbered.id;

-- Recipients
UPDATE tasks SET dropoff_phone = '+14165550100' WHERE dropoff_phone IS NOT NULL;

-- Slack: no program channels and no delivery summaries
UPDATE programs SET slack_channel_id = NULL, send_delivery_summaries = false;

-- The restore leaves this table empty, but make sure
DELETE FROM scheduled_messages;

DO $$
DECLARE
  problems text[] := '{}';
  n bigint;
BEGIN
  SELECT count(*) INTO n FROM allowed_users;
  IF n = 0 THEN
    problems := array_append(problems, 'no users matched allowed_emails (nobody could log in)');
  END IF;

  SELECT count(*) INTO n FROM riders
  WHERE phone IS NOT NULL
    AND phone !~ '^\+1(416|647|437|289|905|365)555[0-9]{4}$'
    AND id NOT IN (SELECT id FROM allowed_riders);
  IF n > 0 THEN problems := array_append(problems, format('%s riders still have a real phone', n)); END IF;

  SELECT count(*) INTO n FROM users
  WHERE (phone IS NOT NULL OR is_dispatcher) AND id NOT IN (SELECT id FROM allowed_users);
  IF n > 0 THEN problems := array_append(problems, format('%s non-allowlisted users have a phone or are dispatchers', n)); END IF;

  SELECT count(*) INTO n FROM tasks WHERE dropoff_phone IS DISTINCT FROM '+14165550100' AND dropoff_phone IS NOT NULL;
  IF n > 0 THEN problems := array_append(problems, format('%s tasks still have a real recipient phone', n)); END IF;

  SELECT count(*) INTO n FROM programs WHERE slack_channel_id IS NOT NULL OR send_delivery_summaries;
  IF n > 0 THEN problems := array_append(problems, format('%s programs still have a Slack channel or summaries on', n)); END IF;

  SELECT count(*) INTO n FROM scheduled_messages;
  IF n > 0 THEN problems := array_append(problems, format('%s scheduled messages remain', n)); END IF;

  IF cardinality(problems) > 0 THEN
    RAISE EXCEPTION 'Staging scrub check failed: %', array_to_string(problems, '; ');
  END IF;

  RAISE NOTICE 'Staging scrub check passed';
END
$$;

COMMIT;
