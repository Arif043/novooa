CREATE TABLE IF NOT EXISTS model_catalog (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  tags_json TEXT NOT NULL DEFAULT '[]',
  scope TEXT NOT NULL CHECK(scope IN ('system', 'team')),
  team_id TEXT REFERENCES teams(id) ON DELETE CASCADE,
  runtime TEXT NOT NULL CHECK(runtime = 'onnx'),
  artifact_reference_json TEXT NOT NULL,
  contract_json TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK(
    (scope = 'system' AND team_id IS NULL) OR
    (scope = 'team' AND team_id IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_model_catalog_scope_team
  ON model_catalog(scope, team_id);

INSERT OR IGNORE INTO schema_migrations(version) VALUES ('004_model_catalog');
