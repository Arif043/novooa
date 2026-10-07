-- Drizzle migriert atomar; Fremdschlüssel bleiben aktiv und werden am Commit geprüft.
PRAGMA defer_foreign_keys=ON;
--> statement-breakpoint
CREATE TABLE `__folder_relationship_guard` (`valid` integer NOT NULL CHECK (`valid` = 1));
--> statement-breakpoint
INSERT INTO `__folder_relationship_guard` (`valid`)
SELECT CASE WHEN EXISTS (
  SELECT 1 FROM file_folders AS child LEFT JOIN file_folders AS parent ON parent.id = child.parent_folder_id
  WHERE child.parent_folder_id IS NOT NULL AND (parent.id IS NULL OR parent.team_id <> child.team_id)
) OR EXISTS (
  SELECT 1 FROM files LEFT JOIN file_folders AS folder ON folder.id = files.folder_id
  WHERE files.folder_id IS NOT NULL AND (folder.id IS NULL OR folder.team_id <> files.team_id)
) OR EXISTS (
  WITH RECURSIVE ancestry(origin, id, parent) AS (
    SELECT id, id, parent_folder_id FROM file_folders
    UNION
    SELECT ancestry.origin, folder.id, folder.parent_folder_id FROM file_folders AS folder
    JOIN ancestry ON folder.id = ancestry.parent
  )
  SELECT 1 FROM ancestry WHERE origin = parent
) THEN 0 ELSE 1 END;
--> statement-breakpoint
DROP TABLE `__folder_relationship_guard`;
--> statement-breakpoint
CREATE TEMP TABLE `__folders_backup` AS SELECT * FROM file_folders;
--> statement-breakpoint
CREATE TEMP TABLE `__files_backup` AS SELECT * FROM files;
--> statement-breakpoint
CREATE TEMP TABLE `__folder_versions_backup` AS SELECT rowid AS saved_rowid, * FROM file_versions;
--> statement-breakpoint
-- DROP TABLE files löscht Versionen per Kaskade; die unabhängige Kopie erhält auch deren Reihenfolge.
DROP TABLE files;
--> statement-breakpoint
DROP TABLE file_folders;
--> statement-breakpoint
CREATE TABLE `file_folders` (
	`id` text PRIMARY KEY NOT NULL,
	`team_id` text NOT NULL,
	`owner_uid` text NOT NULL,
	`name` text NOT NULL,
	`parent_folder_id` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`team_id`,`parent_folder_id`) REFERENCES `file_folders`(`team_id`,`id`) ON UPDATE no action ON DELETE cascade,
	CONSTRAINT "file_folders_not_self_parent" CHECK("file_folders"."parent_folder_id" IS NULL OR "file_folders"."parent_folder_id" <> "file_folders"."id")
);

--> statement-breakpoint
CREATE INDEX `idx_file_folders_team_parent` ON `file_folders` (`team_id`,`parent_folder_id`);
--> statement-breakpoint
CREATE UNIQUE INDEX `idx_file_folders_team_id_id` ON `file_folders` (`team_id`,`id`);
--> statement-breakpoint
CREATE TABLE `files` (
	`id` text PRIMARY KEY NOT NULL,
	`team_id` text NOT NULL,
	`owner_uid` text NOT NULL,
	`display_name` text NOT NULL,
	`folder_id` text,
	`current_version_id` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`team_id`,`folder_id`) REFERENCES `file_folders`(`team_id`,`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`id`,`current_version_id`) REFERENCES `file_versions`(`file_id`,`id`) ON UPDATE no action ON DELETE no action
);

--> statement-breakpoint
CREATE INDEX `idx_files_team_folder` ON `files` (`team_id`,`folder_id`);
--> statement-breakpoint
INSERT INTO file_folders SELECT * FROM `__folders_backup`;
--> statement-breakpoint
INSERT INTO files SELECT * FROM `__files_backup`;
--> statement-breakpoint
INSERT INTO file_versions (rowid, id, file_id, created_by_uid, display_name, storage_path, content_type, size_bytes, created_at)
SELECT saved_rowid, id, file_id, created_by_uid, display_name, storage_path, content_type, size_bytes, created_at
FROM `__folder_versions_backup` ORDER BY saved_rowid;
--> statement-breakpoint
DROP TABLE `__folders_backup`;
--> statement-breakpoint
DROP TABLE `__files_backup`;
--> statement-breakpoint
DROP TABLE `__folder_versions_backup`;
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
