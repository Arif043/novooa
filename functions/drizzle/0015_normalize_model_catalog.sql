-- Bereich und Runtime müssen dem aktuellen Fachmodell entsprechen.
CREATE TABLE `__model_catalog_guard` (`valid` integer NOT NULL CHECK (`valid` = 1));
--> statement-breakpoint
INSERT INTO `__model_catalog_guard` (`valid`)
SELECT CASE WHEN runtime = 'onnx' AND
  ((scope = 'system' AND team_id IS NULL) OR (scope = 'team' AND team_id IS NOT NULL))
  THEN 1 ELSE 0 END FROM model_catalog;
--> statement-breakpoint
DROP TABLE `__model_catalog_guard`;
--> statement-breakpoint
CREATE TABLE `__new_model_catalog` (
	`id` text PRIMARY KEY NOT NULL,
	`title` text NOT NULL,
	`description` text NOT NULL,
	`translations_json` text DEFAULT '{}' NOT NULL,
	`tags_json` text DEFAULT '[]' NOT NULL,
	`team_id` text,
	`artifact_reference_json` text NOT NULL,
	`contract_json` text NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
INSERT INTO `__new_model_catalog`("id", "title", "description", "translations_json", "tags_json", "team_id", "artifact_reference_json", "contract_json", "created_at", "updated_at") SELECT "id", "title", "description", "translations_json", "tags_json", "team_id", "artifact_reference_json", "contract_json", "created_at", "updated_at" FROM `model_catalog`;--> statement-breakpoint
DROP TABLE `model_catalog`;--> statement-breakpoint
ALTER TABLE `__new_model_catalog` RENAME TO `model_catalog`;--> statement-breakpoint
CREATE INDEX `idx_model_catalog_team` ON `model_catalog` (`team_id`);