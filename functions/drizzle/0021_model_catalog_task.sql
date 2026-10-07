ALTER TABLE `model_catalog` ADD `task` text DEFAULT 'other' NOT NULL;--> statement-breakpoint
ALTER TABLE `model_catalog` ADD `languages_json` text DEFAULT '[]' NOT NULL;