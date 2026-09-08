CREATE TABLE IF NOT EXISTS file_folders (
  id TEXT PRIMARY KEY,
  team_id TEXT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  owner_uid TEXT NOT NULL,
  name TEXT NOT NULL,
  parent_folder_id TEXT REFERENCES file_folders(id) ON DELETE CASCADE,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_file_folders_team_parent
  ON file_folders(team_id, parent_folder_id);
