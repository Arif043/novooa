-- Keine verwaisten Aufgabenbezüge oder widersprüchlichen Teamzuordnungen übernehmen.
CREATE TABLE `__task_trigger_team_guard` (`valid` integer NOT NULL CHECK (`valid` = 1));
--> statement-breakpoint
INSERT INTO `__task_trigger_team_guard` (`valid`)
SELECT CASE WHEN triggers.team_id = tasks.team_id THEN 1 ELSE 0 END
FROM task_triggers AS triggers LEFT JOIN tasks ON tasks.id = triggers.task_id;
--> statement-breakpoint
DROP TABLE `__task_trigger_team_guard`;
--> statement-breakpoint
CREATE TABLE `__new_task_triggers` (
	`id` text PRIMARY KEY NOT NULL,
	`task_id` text NOT NULL,
	`type` text NOT NULL,
	`enabled` integer DEFAULT 1 NOT NULL,
	`config_json` text DEFAULT '{}' NOT NULL,
	`event_config_json` text DEFAULT '{}' NOT NULL,
	`policy_json` text DEFAULT '{}' NOT NULL,
	`next_run_at` text,
	`last_run_at` text,
	`last_run_id` text,
	`created_by_uid` text NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`task_id`) REFERENCES `tasks`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
INSERT INTO `__new_task_triggers`("id", "task_id", "type", "enabled", "config_json", "event_config_json", "policy_json", "next_run_at", "last_run_at", "last_run_id", "created_by_uid", "created_at", "updated_at") SELECT "id", "task_id", "type", "enabled", "config_json", "event_config_json", "policy_json", "next_run_at", "last_run_at", "last_run_id", "created_by_uid", "created_at", "updated_at" FROM `task_triggers`;--> statement-breakpoint
DROP TABLE `task_triggers`;--> statement-breakpoint
ALTER TABLE `__new_task_triggers` RENAME TO `task_triggers`;--> statement-breakpoint
CREATE INDEX `idx_task_triggers_task` ON `task_triggers` (`task_id`,`enabled`);--> statement-breakpoint
CREATE INDEX `idx_task_triggers_due` ON `task_triggers` (`enabled`,`next_run_at`);