-- Widersprüchliche Teamzuordnungen dürfen nicht stillschweigend übernommen werden.
CREATE TABLE `__run_dependents_team_guard` (`valid` integer NOT NULL CHECK (`valid` = 1));
--> statement-breakpoint
INSERT INTO `__run_dependents_team_guard` (`valid`)
SELECT CASE WHEN jobs.team_id = runs.team_id THEN 1 ELSE 0 END
FROM task_run_jobs AS jobs LEFT JOIN task_runs AS runs ON runs.id = jobs.run_id
UNION ALL
SELECT CASE WHEN steps.team_id = runs.team_id THEN 1 ELSE 0 END
FROM task_run_steps AS steps LEFT JOIN task_runs AS runs ON runs.id = steps.run_id;
--> statement-breakpoint
DROP TABLE `__run_dependents_team_guard`;
--> statement-breakpoint
CREATE TABLE `__new_task_run_jobs` (
	`id` text PRIMARY KEY NOT NULL,
	`run_id` text NOT NULL,
	`mode` text NOT NULL,
	`status` text NOT NULL,
	`attempts` integer DEFAULT 0 NOT NULL,
	`available_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`lease_expires_at` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`run_id`) REFERENCES `task_runs`(`id`) ON UPDATE no action ON DELETE cascade,
	CONSTRAINT "task_run_jobs_mode" CHECK("__new_task_run_jobs"."mode" IN ('start', 'resume')),
	CONSTRAINT "task_run_jobs_status" CHECK("__new_task_run_jobs"."status" IN ('queued', 'leased', 'completed', 'failed'))
);
--> statement-breakpoint
INSERT INTO `__new_task_run_jobs`("id", "run_id", "mode", "status", "attempts", "available_at", "lease_expires_at", "created_at", "updated_at") SELECT "id", "run_id", "mode", "status", "attempts", "available_at", "lease_expires_at", "created_at", "updated_at" FROM `task_run_jobs`;--> statement-breakpoint
DROP TABLE `task_run_jobs`;--> statement-breakpoint
ALTER TABLE `__new_task_run_jobs` RENAME TO `task_run_jobs`;--> statement-breakpoint
CREATE INDEX `idx_task_run_jobs_next` ON `task_run_jobs` (`status`,`available_at`,`lease_expires_at`);--> statement-breakpoint
CREATE UNIQUE INDEX `task_run_jobs_run_id_unique` ON `task_run_jobs` (`run_id`);--> statement-breakpoint
CREATE TABLE `__new_task_run_steps` (
	`run_id` text NOT NULL,
	`step_path` text NOT NULL,
	`result_json` text NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	PRIMARY KEY(`run_id`, `step_path`),
	FOREIGN KEY (`run_id`) REFERENCES `task_runs`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
INSERT INTO `__new_task_run_steps`("run_id", "step_path", "result_json", "created_at") SELECT "run_id", "step_path", "result_json", "created_at" FROM `task_run_steps`;--> statement-breakpoint
DROP TABLE `task_run_steps`;--> statement-breakpoint
ALTER TABLE `__new_task_run_steps` RENAME TO `task_run_steps`;