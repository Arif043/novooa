CREATE TABLE `runtime_invitations` (
	`code_hash` text PRIMARY KEY NOT NULL,
	`uid` text NOT NULL,
	`expires_at` text NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`uid`) REFERENCES `user_profiles`(`uid`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `idx_runtime_invitations_uid` ON `runtime_invitations` (`uid`);--> statement-breakpoint
CREATE TABLE `runtime_password_credentials` (
	`uid` text PRIMARY KEY NOT NULL,
	`password_hash` text NOT NULL,
	`salt` text NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`uid`) REFERENCES `user_profiles`(`uid`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
ALTER TABLE `task_runs` ADD `started_by_uid` text;--> statement-breakpoint
ALTER TABLE `task_runs` ADD `reviewed_by_uid` text;--> statement-breakpoint
ALTER TABLE `user_profiles` ADD `login_name` text;--> statement-breakpoint
CREATE UNIQUE INDEX `idx_user_profiles_login_name` ON `user_profiles` (`login_name`);--> statement-breakpoint
DROP TABLE `runtime_sessions`;--> statement-breakpoint
CREATE TABLE `runtime_sessions` (
	`token_hash` text PRIMARY KEY NOT NULL,
	`uid` text NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`expires_at` text NOT NULL,
	FOREIGN KEY (`uid`) REFERENCES `user_profiles`(`uid`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `idx_runtime_sessions_uid` ON `runtime_sessions` (`uid`);--> statement-breakpoint
DROP TABLE `runtime_access_credential`;--> statement-breakpoint
UPDATE `team_members` SET `role` = 'admin' WHERE `role` = 'owner';