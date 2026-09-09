CREATE TABLE IF NOT EXISTS application_logs (
  id TEXT PRIMARY KEY,
  team_id TEXT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  level TEXT NOT NULL CHECK(level IN ('info', 'error')),
  event TEXT NOT NULL,
  message TEXT,
  data_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_application_logs_team_created
  ON application_logs(team_id, created_at DESC);
