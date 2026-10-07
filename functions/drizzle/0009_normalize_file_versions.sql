-- Drizzle führt diese Migration in einer Transaktion aus. Fremdschlüssel
-- bleiben aktiv; die zirkuläre Versionsreferenz wird am Commit geprüft.
PRAGMA defer_foreign_keys=ON;--> statement-breakpoint
CREATE TABLE `__new_file_versions` (
	`id` text PRIMARY KEY NOT NULL,
	`file_id` text NOT NULL,
	`created_by_uid` text NOT NULL,
	`display_name` text NOT NULL,
	`storage_path` text NOT NULL,
	`content_type` text DEFAULT 'application/octet-stream' NOT NULL,
	`size_bytes` integer DEFAULT 0 NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`file_id`) REFERENCES `files`(`id`) ON UPDATE no action ON DELETE cascade,
	CONSTRAINT "file_versions_nonnegative_size" CHECK("__new_file_versions"."size_bytes" >= 0)
);
--> statement-breakpoint
INSERT INTO `__new_file_versions`("id", "file_id", "created_by_uid", "display_name", "storage_path", "content_type", "size_bytes", "created_at") SELECT "id", "file_id", "created_by_uid", "display_name", "storage_path", "content_type", "size_bytes", "created_at" FROM `file_versions`;--> statement-breakpoint
DROP TABLE `file_versions`;--> statement-breakpoint
ALTER TABLE `__new_file_versions` RENAME TO `file_versions`;--> statement-breakpoint
CREATE UNIQUE INDEX `idx_file_versions_file_id_id` ON `file_versions` (`file_id`,`id`);--> statement-breakpoint
CREATE TABLE `__new_files` (
	`id` text PRIMARY KEY NOT NULL,
	`team_id` text NOT NULL,
	`owner_uid` text NOT NULL,
	`display_name` text NOT NULL,
	`folder_id` text,
	`current_version_id` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`id`,`current_version_id`) REFERENCES `file_versions`(`file_id`,`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
INSERT INTO `__new_files`("id", "team_id", "owner_uid", "display_name", "folder_id", "current_version_id", "created_at", "updated_at") SELECT "id", "team_id", "owner_uid", "display_name", "folder_id", "current_version_id", "created_at", "updated_at" FROM `files`;--> statement-breakpoint
-- DROP TABLE files löst ON DELETE CASCADE aus. Die Kopie hat absichtlich
-- keine Fremdschlüssel und bleibt während des Tabellenumbaus erhalten.
CREATE TEMP TABLE `file_versions_backup` AS SELECT * FROM `file_versions`;--> statement-breakpoint
DROP TABLE `files`;--> statement-breakpoint
ALTER TABLE `__new_files` RENAME TO `files`;--> statement-breakpoint
CREATE INDEX `idx_files_team_folder` ON `files` (`team_id`,`folder_id`);
--> statement-breakpoint
INSERT INTO `file_versions` SELECT * FROM `file_versions_backup`;
--> statement-breakpoint
DROP TABLE `file_versions_backup`;
