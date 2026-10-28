ALTER TABLE `activities` ADD `effects_json` text DEFAULT '[]' NOT NULL;--> statement-breakpoint
ALTER TABLE `task_runs` ADD `graph_snapshot_json` text;