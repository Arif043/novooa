CREATE TABLE `__new_runtime_sessions` (
	`token_hash` text PRIMARY KEY NOT NULL,
	`id` text NOT NULL,
	`uid` text NOT NULL,
	`device_app` text DEFAULT '' NOT NULL,
	`device_os` text DEFAULT 'unknown' NOT NULL,
	`device_browser` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`last_used_at` text NOT NULL,
	`expires_at` text NOT NULL,
	FOREIGN KEY (`uid`) REFERENCES `user_profiles`(`uid`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
INSERT INTO `__new_runtime_sessions` (`token_hash`, `id`, `uid`, `created_at`, `last_used_at`, `expires_at`)
SELECT `token_hash`, lower(hex(randomblob(16))), `uid`, strftime('%Y-%m-%dT%H:%M:%fZ', `created_at`),
	strftime('%Y-%m-%dT%H:%M:%fZ', `expires_at`, '-7 days'), `expires_at`
FROM `runtime_sessions`;
--> statement-breakpoint
DROP TABLE `runtime_sessions`;
--> statement-breakpoint
ALTER TABLE `__new_runtime_sessions` RENAME TO `runtime_sessions`;
--> statement-breakpoint
CREATE INDEX `idx_runtime_sessions_uid` ON `runtime_sessions` (`uid`);
--> statement-breakpoint
CREATE UNIQUE INDEX `idx_runtime_sessions_id` ON `runtime_sessions` (`id`);
