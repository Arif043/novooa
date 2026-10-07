-- Fremdschlüssel bleiben während des transaktionalen Tabellenumbaus aktiv.
CREATE TABLE `__new_language_models` (
	`id` text PRIMARY KEY NOT NULL,
	`connection_id` text NOT NULL,
	`name` text NOT NULL,
	`model_id` text NOT NULL,
	`capabilities_json` text DEFAULT '{}' NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`connection_id`) REFERENCES `language_model_connections`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
INSERT INTO `__new_language_models`("id", "connection_id", "name", "model_id", "capabilities_json", "created_at", "updated_at") SELECT "id", "connection_id", "name", "model_id", "capabilities_json", "created_at", "updated_at" FROM `language_models`;--> statement-breakpoint
DROP TABLE `language_models`;--> statement-breakpoint
ALTER TABLE `__new_language_models` RENAME TO `language_models`;--> statement-breakpoint
CREATE INDEX `language_models_connection_id_idx` ON `language_models` (`connection_id`);
