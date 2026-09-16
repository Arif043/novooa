CREATE TABLE IF NOT EXISTS document_collections (
  id TEXT NOT NULL,
  team_id TEXT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (team_id, id)
);

CREATE TABLE IF NOT EXISTS documents (
  id TEXT NOT NULL,
  team_id TEXT NOT NULL,
  collection_id TEXT NOT NULL,
  data_json TEXT NOT NULL CHECK (
    json_valid(data_json) AND json_type(data_json) = 'object'
  ),
  version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (team_id, collection_id, id),
  FOREIGN KEY (team_id, collection_id)
    REFERENCES document_collections(team_id, id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_documents_team_collection_updated
  ON documents(team_id, collection_id, updated_at DESC, id);

INSERT OR IGNORE INTO schema_migrations(version) VALUES ('012_document_store');
