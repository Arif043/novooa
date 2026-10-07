-- Fremdschlüssel bleiben aktiv; Dateien und Versionen werden gemeinsam wiederhergestellt.
PRAGMA defer_foreign_keys=ON;
--> statement-breakpoint
CREATE TABLE __file_ownership_guard (valid integer NOT NULL CHECK (valid = 1));
--> statement-breakpoint
INSERT INTO __file_ownership_guard
SELECT CASE WHEN EXISTS (
  SELECT 1 FROM files LEFT JOIN file_folders AS folder ON folder.id = files.folder_id
  WHERE files.folder_id IS NOT NULL AND (folder.id IS NULL OR folder.team_id <> files.team_id)
) THEN 0 ELSE 1 END;
--> statement-breakpoint
DROP TABLE __file_ownership_guard;
--> statement-breakpoint
CREATE TEMP TABLE __file_ownership_backup AS SELECT * FROM files;
--> statement-breakpoint
CREATE TEMP TABLE __file_ownership_versions AS SELECT rowid AS saved_rowid, * FROM file_versions;
--> statement-breakpoint
DROP TABLE files;
--> statement-breakpoint
CREATE TABLE files (
  id text PRIMARY KEY NOT NULL,
  root_team_id text,
  owner_uid text NOT NULL,
  display_name text NOT NULL,
  folder_id text,
  current_version_id text,
  created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
  FOREIGN KEY (root_team_id) REFERENCES teams(id) ON DELETE cascade,
  FOREIGN KEY (folder_id) REFERENCES file_folders(id),
  FOREIGN KEY (id, current_version_id) REFERENCES file_versions(file_id, id),
  CONSTRAINT files_one_location CHECK (
    (folder_id IS NULL AND root_team_id IS NOT NULL) OR (folder_id IS NOT NULL AND root_team_id IS NULL)
  )
);
--> statement-breakpoint
CREATE INDEX idx_files_root_team ON files(root_team_id);
--> statement-breakpoint
CREATE INDEX idx_files_folder ON files(folder_id);
--> statement-breakpoint
INSERT INTO files (id, root_team_id, owner_uid, display_name, folder_id, current_version_id, created_at, updated_at)
SELECT id, CASE WHEN folder_id IS NULL THEN team_id ELSE NULL END,
  owner_uid, display_name, folder_id, current_version_id, created_at, updated_at FROM __file_ownership_backup;
--> statement-breakpoint
INSERT INTO file_versions (rowid, id, file_id, created_by_uid, display_name, storage_path, content_type, size_bytes, created_at)
SELECT saved_rowid, id, file_id, created_by_uid, display_name, storage_path, content_type, size_bytes, created_at
FROM __file_ownership_versions ORDER BY saved_rowid;
--> statement-breakpoint
DROP TABLE __file_ownership_backup;
--> statement-breakpoint
DROP TABLE __file_ownership_versions;
--> statement-breakpoint
CREATE TRIGGER files_preserve_team BEFORE UPDATE OF root_team_id, folder_id ON files
BEGIN
  SELECT RAISE(ABORT, 'Die Datei darf nicht in ein anderes Team verschoben werden.')
  WHERE coalesce(OLD.root_team_id, (SELECT team_id FROM file_folders WHERE id = OLD.folder_id))
    IS NOT coalesce(NEW.root_team_id, (SELECT team_id FROM file_folders WHERE id = NEW.folder_id));
END;
--> statement-breakpoint
CREATE TRIGGER file_folders_preserve_file_team BEFORE UPDATE OF team_id ON file_folders
WHEN OLD.team_id <> NEW.team_id AND EXISTS (SELECT 1 FROM files WHERE folder_id = OLD.id)
BEGIN
  SELECT RAISE(ABORT, 'Ein Ordner mit Dateien darf nicht in ein anderes Team verschoben werden.');
END;
--> statement-breakpoint
-- Ordnerbezüge schützen weiterhin gefüllte Ordner vor direkter Löschung.
-- Bei Teamlöschung werden ihre Dateien zuerst entfernt, danach kaskadieren die Ordner.
CREATE TRIGGER teams_delete_assigned_files BEFORE DELETE ON teams
BEGIN
  DELETE FROM files WHERE folder_id IN (SELECT id FROM file_folders WHERE team_id = OLD.id);
END;
