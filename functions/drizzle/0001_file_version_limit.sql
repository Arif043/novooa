CREATE TABLE `workspace_file_settings` (
	`team_id` text PRIMARY KEY NOT NULL,
	`version_limit` integer NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade
);
