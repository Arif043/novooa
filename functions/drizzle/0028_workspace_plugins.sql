CREATE TABLE `workspace_plugins` (
	`team_id` text NOT NULL,
	`plugin_id` text NOT NULL,
	`enabled_at` text NOT NULL,
	`enabled_by_uid` text,
	PRIMARY KEY(`team_id`, `plugin_id`),
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade
);
