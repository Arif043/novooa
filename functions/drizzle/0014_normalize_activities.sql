-- Team und Aufgabe müssen zum Run passen; keine Historie stillschweigend neu zuordnen.
CREATE TABLE `__activity_run_guard` (`valid` integer NOT NULL CHECK (`valid` = 1));
--> statement-breakpoint
INSERT INTO `__activity_run_guard` (`valid`)
SELECT CASE WHEN activities.team_id = runs.team_id AND activities.task_id = runs.task_id THEN 1 ELSE 0 END
FROM activities LEFT JOIN task_runs AS runs ON runs.id = activities.run_id;
--> statement-breakpoint
DROP TABLE `__activity_run_guard`;
--> statement-breakpoint
CREATE TABLE `__new_activities` (
	`id` text PRIMARY KEY NOT NULL,
	`run_id` text NOT NULL,
	`node_id` text,
	`target` text NOT NULL,
	`primitive` text,
	`title` text NOT NULL,
	`status` text NOT NULL,
	`input` text DEFAULT '' NOT NULL,
	`output` text DEFAULT '' NOT NULL,
	`outputs_json` text DEFAULT '{}' NOT NULL,
	`message` text DEFAULT '' NOT NULL,
	`duration_ms` integer,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`console_json` text DEFAULT '{}' NOT NULL,
	FOREIGN KEY (`run_id`) REFERENCES `task_runs`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
INSERT INTO `__new_activities`("id", "run_id", "node_id", "target", "primitive", "title", "status", "input", "output", "outputs_json", "message", "duration_ms", "created_at", "console_json") SELECT "id", "run_id", "node_id", "target", "primitive", "title", "status", "input", "output", "outputs_json", "message", "duration_ms", "created_at", "console_json" FROM `activities`;--> statement-breakpoint
DROP TABLE `activities`;--> statement-breakpoint
ALTER TABLE `__new_activities` RENAME TO `activities`;--> statement-breakpoint
CREATE INDEX `idx_activities_run_created` ON `activities` (`run_id`,`created_at`);