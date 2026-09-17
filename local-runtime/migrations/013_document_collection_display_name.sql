CREATE UNIQUE INDEX IF NOT EXISTS idx_document_collections_team_display_name
  ON document_collections(team_id, display_name COLLATE BINARY);

INSERT OR IGNORE INTO schema_migrations(version) VALUES ('013_document_collection_display_name');
