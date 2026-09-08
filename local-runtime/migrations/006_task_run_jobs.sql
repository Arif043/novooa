CREATE TABLE IF NOT EXISTS task_run_jobs (
  id TEXT PRIMARY KEY,
  team_id TEXT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  run_id TEXT NOT NULL REFERENCES task_runs(id) ON DELETE CASCADE,
  mode TEXT NOT NULL CHECK (mode IN ('start', 'resume')),
  status TEXT NOT NULL CHECK (status IN ('queued', 'leased', 'completed', 'failed')),
  attempts INTEGER NOT NULL DEFAULT 0,
  available_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  lease_expires_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (team_id, run_id)
);

CREATE INDEX IF NOT EXISTS idx_task_run_jobs_next
  ON task_run_jobs(status, available_at, lease_expires_at);
