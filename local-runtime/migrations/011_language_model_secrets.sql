CREATE TABLE IF NOT EXISTS language_model_secrets (
  secret_ref TEXT PRIMARY KEY,
  encrypted_value TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT OR IGNORE INTO schema_migrations(version) VALUES ('011_language_model_secrets');
