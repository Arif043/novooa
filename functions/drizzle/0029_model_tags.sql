CREATE TABLE `model_tags` (
	`key` text PRIMARY KEY NOT NULL,
	`parent` text,
	`labels_json` text NOT NULL,
	`synonyms_json` text DEFAULT '{}' NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL
);
