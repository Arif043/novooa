-- Metadaten und Versionsreihenfolge bleiben bei aktiven Fremdschlüsseln erhalten.
PRAGMA defer_foreign_keys=ON;
--> statement-breakpoint
CREATE TABLE __folder_ownership_guard (valid integer NOT NULL CHECK (valid = 1));
--> statement-breakpoint
INSERT INTO __folder_ownership_guard
SELECT CASE WHEN EXISTS (
  SELECT 1 FROM file_folders AS child LEFT JOIN file_folders AS parent ON parent.id = child.parent_folder_id
  WHERE child.parent_folder_id IS NOT NULL AND (parent.id IS NULL OR parent.team_id <> child.team_id)
) OR EXISTS (
  WITH RECURSIVE ancestry(origin, id, parent) AS (
    SELECT id, id, parent_folder_id FROM file_folders
    UNION
    SELECT ancestry.origin, folder.id, folder.parent_folder_id FROM file_folders AS folder
    JOIN ancestry ON folder.id = ancestry.parent
  ) SELECT 1 FROM ancestry WHERE origin = parent
) THEN 0 ELSE 1 END;
--> statement-breakpoint
DROP TABLE __folder_ownership_guard;
--> statement-breakpoint
CREATE TEMP TABLE __folder_ownership_folders AS SELECT * FROM file_folders;
--> statement-breakpoint
CREATE TEMP TABLE __folder_ownership_files AS SELECT * FROM files;
--> statement-breakpoint
CREATE TEMP TABLE __folder_ownership_versions AS SELECT rowid AS saved_rowid, * FROM file_versions;
--> statement-breakpoint
DROP TRIGGER teams_delete_assigned_files;
--> statement-breakpoint
DROP TRIGGER file_folders_preserve_file_team;
--> statement-breakpoint
DROP TABLE files;
--> statement-breakpoint
DROP TABLE file_folders;
--> statement-breakpoint
CREATE TABLE file_folders (
  id text PRIMARY KEY NOT NULL,
  root_team_id text,
  owner_uid text NOT NULL,
  name text NOT NULL,
  parent_folder_id text,
  created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
  FOREIGN KEY (root_team_id) REFERENCES teams(id) ON DELETE cascade,
  FOREIGN KEY (parent_folder_id) REFERENCES file_folders(id) ON DELETE cascade,
  CONSTRAINT file_folders_one_location CHECK (
    (parent_folder_id IS NULL AND root_team_id IS NOT NULL) OR
    (parent_folder_id IS NOT NULL AND root_team_id IS NULL)
  ),
  CONSTRAINT file_folders_not_self_parent CHECK (parent_folder_id IS NULL OR parent_folder_id <> id)
);
--> statement-breakpoint
CREATE INDEX idx_file_folders_root_team ON file_folders(root_team_id);
--> statement-breakpoint
CREATE INDEX idx_file_folders_parent ON file_folders(parent_folder_id);
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
INSERT INTO file_folders (id, root_team_id, owner_uid, name, parent_folder_id, created_at, updated_at)
SELECT id, CASE WHEN parent_folder_id IS NULL THEN team_id ELSE NULL END,
  owner_uid, name, parent_folder_id, created_at, updated_at FROM __folder_ownership_folders;
--> statement-breakpoint
INSERT INTO files SELECT * FROM __folder_ownership_files;
--> statement-breakpoint
INSERT INTO file_versions (rowid, id, file_id, created_by_uid, display_name, storage_path, content_type, size_bytes, created_at)
SELECT saved_rowid, id, file_id, created_by_uid, display_name, storage_path, content_type, size_bytes, created_at
FROM __folder_ownership_versions ORDER BY saved_rowid;
--> statement-breakpoint
DROP TABLE __folder_ownership_folders;
--> statement-breakpoint
DROP TABLE __folder_ownership_files;
--> statement-breakpoint
DROP TABLE __folder_ownership_versions;
--> statement-breakpoint
CREATE TRIGGER file_folders_no_cycle_insert BEFORE INSERT ON file_folders
BEGIN
  SELECT RAISE(ABORT, 'Die Ordnerhierarchie darf keinen Zyklus enthalten.')
  WHERE NEW.parent_folder_id IS NOT NULL AND EXISTS (
    WITH RECURSIVE ancestors(id, parent) AS (
      SELECT id, parent_folder_id FROM file_folders WHERE id = NEW.parent_folder_id
      UNION
      SELECT folder.id, folder.parent_folder_id FROM file_folders AS folder
      JOIN ancestors ON folder.id = ancestors.parent
    )
    SELECT 1 FROM ancestors WHERE id = NEW.id OR parent = NEW.id
  );
END;
--> statement-breakpoint
CREATE TRIGGER file_folders_no_cycle_update BEFORE UPDATE OF id, parent_folder_id ON file_folders
BEGIN
  SELECT RAISE(ABORT, 'Die Ordnerhierarchie darf keinen Zyklus enthalten.')
  WHERE NEW.parent_folder_id IS NOT NULL AND EXISTS (
    WITH RECURSIVE ancestors(id, parent) AS (
      SELECT id, parent_folder_id FROM file_folders WHERE id = NEW.parent_folder_id
      UNION
      SELECT folder.id, folder.parent_folder_id FROM file_folders AS folder
      JOIN ancestors ON folder.id = ancestors.parent
    )
    SELECT 1 FROM ancestors WHERE id = NEW.id OR parent = NEW.id
  );
END;

--> statement-breakpoint
CREATE TRIGGER file_folders_preserve_team BEFORE UPDATE OF root_team_id, parent_folder_id ON file_folders
BEGIN
  SELECT RAISE(ABORT, 'Der Ordner darf nicht in ein anderes Team verschoben werden.')
  WHERE coalesce(OLD.root_team_id, (WITH RECURSIVE ancestors(id, parent, root_team) AS (
      SELECT id, parent_folder_id, root_team_id FROM file_folders WHERE id = OLD.parent_folder_id
      UNION
      SELECT folder.id, folder.parent_folder_id, folder.root_team_id FROM file_folders AS folder
      JOIN ancestors ON folder.id = ancestors.parent
    ) SELECT root_team FROM ancestors WHERE root_team IS NOT NULL))
    IS NOT coalesce(NEW.root_team_id, (WITH RECURSIVE ancestors(id, parent, root_team) AS (
      SELECT id, parent_folder_id, root_team_id FROM file_folders WHERE id = NEW.parent_folder_id
      UNION
      SELECT folder.id, folder.parent_folder_id, folder.root_team_id FROM file_folders AS folder
      JOIN ancestors ON folder.id = ancestors.parent
    ) SELECT root_team FROM ancestors WHERE root_team IS NOT NULL));
END;
--> statement-breakpoint
CREATE TRIGGER files_preserve_team BEFORE UPDATE OF root_team_id, folder_id ON files
BEGIN
  SELECT RAISE(ABORT, 'Die Datei darf nicht in ein anderes Team verschoben werden.')
  WHERE coalesce(OLD.root_team_id, (WITH RECURSIVE ancestors(id, parent, root_team) AS (
      SELECT id, parent_folder_id, root_team_id FROM file_folders WHERE id = OLD.folder_id
      UNION
      SELECT folder.id, folder.parent_folder_id, folder.root_team_id FROM file_folders AS folder
      JOIN ancestors ON folder.id = ancestors.parent
    ) SELECT root_team FROM ancestors WHERE root_team IS NOT NULL))
    IS NOT coalesce(NEW.root_team_id, (WITH RECURSIVE ancestors(id, parent, root_team) AS (
      SELECT id, parent_folder_id, root_team_id FROM file_folders WHERE id = NEW.folder_id
      UNION
      SELECT folder.id, folder.parent_folder_id, folder.root_team_id FROM file_folders AS folder
      JOIN ancestors ON folder.id = ancestors.parent
    ) SELECT root_team FROM ancestors WHERE root_team IS NOT NULL));
END;
--> statement-breakpoint
CREATE TRIGGER teams_delete_assigned_files BEFORE DELETE ON teams
BEGIN
  DELETE FROM files WHERE folder_id IN (
    WITH RECURSIVE owned_folders(id) AS (
      SELECT id FROM file_folders WHERE root_team_id = OLD.id
      UNION
      SELECT folder.id FROM file_folders AS folder JOIN owned_folders ON folder.parent_folder_id = owned_folders.id
    ) SELECT id FROM owned_folders
  );
END;
