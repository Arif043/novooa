DROP TABLE `runtime_password_credentials`;--> statement-breakpoint
CREATE TABLE `runtime_password_credentials` (
	`uid` text PRIMARY KEY NOT NULL,
	`encrypted_hash` text NOT NULL,
	`salt` text NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`uid`) REFERENCES `user_profiles`(`uid`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
DELETE FROM `runtime_sessions`;
