-- ==========================================
-- OpenTone Supabase Schema Migration
-- Run this in Supabase Dashboard → SQL Editor
-- ==========================================

-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  email         TEXT UNIQUE NOT NULL,
  country_name  TEXT,
  country_code  TEXT,
  avatar        TEXT,
  age           INT,
  gender        TEXT,
  bio           TEXT,
  goal          INT NOT NULL DEFAULT 0,
  english_level TEXT,
  confidence_title TEXT,
  confidence_emoji TEXT,
  interests     JSONB,
  current_plan  TEXT DEFAULT 'free',
  streak_commitment   INT DEFAULT 0,
  streak_current      INT DEFAULT 0,
  streak_longest      INT DEFAULT 0,
  streak_last_active  TIMESTAMPTZ,
  last_seen     TIMESTAMPTZ,
  friend_ids    UUID[] DEFAULT '{}',
  ai_feedback_enabled BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE users ADD COLUMN IF NOT EXISTS ai_feedback_enabled BOOLEAN NOT NULL DEFAULT false;

-- 2. ACTIVITIES TABLE (history)
CREATE TABLE IF NOT EXISTS activities (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type          TEXT NOT NULL,
  title         TEXT NOT NULL,
  date          TIMESTAMPTZ NOT NULL DEFAULT now(),
  topic         TEXT NOT NULL,
  duration      INT NOT NULL DEFAULT 0,
  image_url     TEXT,
  xp_earned     INT NOT NULL DEFAULT 0,
  is_completed  BOOLEAN NOT NULL DEFAULT false,
  scenario_id   UUID,
  roleplay_session JSONB,
  feedback      JSONB,
  created_at    TIMESTAMPTZ DEFAULT now()
);

-- 3. CALL RECORDS TABLE
CREATE TABLE IF NOT EXISTS call_records (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  participant_id        UUID NOT NULL,
  participant_name      TEXT,
  participant_avatar_url TEXT,
  participant_bio       TEXT,
  participant_interests JSONB,
  call_date             TIMESTAMPTZ NOT NULL DEFAULT now(),
  duration              DOUBLE PRECISION NOT NULL DEFAULT 0,
  user_status           TEXT NOT NULL DEFAULT 'offline'
);

-- 4. JAM SESSIONS TABLE
CREATE TABLE IF NOT EXISTS jam_sessions (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  topic               TEXT NOT NULL,
  suggestions         JSONB NOT NULL DEFAULT '[]',
  phase               TEXT NOT NULL DEFAULT 'preparing',
  seconds_left        INT NOT NULL DEFAULT 30,
  started_prep_at     TIMESTAMPTZ,
  started_speaking_at TIMESTAMPTZ,
  ended_at            TIMESTAMPTZ,
  is_saved            BOOLEAN DEFAULT false,
  created_at          TIMESTAMPTZ DEFAULT now()
);

-- 5. COMPLETED SESSIONS TABLE (streak tracking)
CREATE TABLE IF NOT EXISTS completed_sessions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date             TIMESTAMPTZ NOT NULL DEFAULT now(),
  title            TEXT NOT NULL,
  subtitle         TEXT NOT NULL,
  topic            TEXT NOT NULL,
  duration_minutes INT NOT NULL DEFAULT 0,
  xp               INT NOT NULL DEFAULT 0,
  icon_name        TEXT NOT NULL
);

-- 6. ROLEPLAY SESSIONS TABLE
CREATE TABLE IF NOT EXISTS roleplay_sessions (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  scenario_id        UUID NOT NULL,
  current_line_index INT NOT NULL DEFAULT 0,
  messages           JSONB DEFAULT '[]',
  status             TEXT NOT NULL DEFAULT 'notStarted',
  started_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  ended_at           TIMESTAMPTZ,
  feedback           JSONB,
  xp_earned          INT NOT NULL DEFAULT 100,
  is_saved           BOOLEAN DEFAULT false
);

-- 7. REPORTS TABLE
CREATE TABLE IF NOT EXISTS reports (
  id                 TEXT PRIMARY KEY,
  reporter_user_id   TEXT NOT NULL,
  reported_entity_id TEXT NOT NULL,
  entity_type        TEXT NOT NULL,
  reason             TEXT NOT NULL,
  reason_details     TEXT,
  message            TEXT,
  timestamp          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 8. Legacy migration + RLS hardening
ALTER TABLE users DROP COLUMN IF EXISTS password;

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE jam_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE completed_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE roleplay_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS users_select_own ON users;
DROP POLICY IF EXISTS users_update_own ON users;
DROP POLICY IF EXISTS users_insert_own ON users;
CREATE POLICY users_select_own ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY users_update_own ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY users_insert_own ON users FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS activities_own_all ON activities;
CREATE POLICY activities_own_all ON activities FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS call_records_own_all ON call_records;
CREATE POLICY call_records_own_all ON call_records FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS jam_sessions_own_all ON jam_sessions;
CREATE POLICY jam_sessions_own_all ON jam_sessions FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS completed_sessions_own_all ON completed_sessions;
CREATE POLICY completed_sessions_own_all ON completed_sessions FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS roleplay_sessions_own_all ON roleplay_sessions;
CREATE POLICY roleplay_sessions_own_all ON roleplay_sessions FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 9. RPC Functions
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Securely deletes the currently authenticated user from auth.users
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;
