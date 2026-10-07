CREATE TABLE `user_profiles` (
	`uid` text PRIMARY KEY NOT NULL,
	`email` text DEFAULT '' NOT NULL,
	`display_name` text DEFAULT '' NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL
);
--> statement-breakpoint
-- Ein Benutzerprofil pro UID; bei verschiedenen Profilkopien gewinnt die
-- zuletzt aktualisierte Mitgliedschaft, bei Gleichstand die kleinste Team-ID.
INSERT INTO `user_profiles` (`uid`, `email`, `display_name`, `created_at`, `updated_at`)
SELECT `uid`, `email`, `display_name`, `profile_created_at`, `updated_at`
FROM (
  SELECT *,
    MIN(`created_at`) OVER (PARTITION BY `uid`) AS `profile_created_at`,
    ROW_NUMBER() OVER (PARTITION BY `uid` ORDER BY `updated_at` DESC, `team_id` ASC) AS `profile_rank`
  FROM `team_members`
)
WHERE `profile_rank` = 1;--> statement-breakpoint
CREATE TABLE `__new_team_members` (
	`team_id` text NOT NULL,
	`uid` text NOT NULL,
	`role` text DEFAULT 'member' NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	PRIMARY KEY(`team_id`, `uid`),
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`uid`) REFERENCES `user_profiles`(`uid`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
INSERT INTO `__new_team_members`("team_id", "uid", "role", "created_at", "updated_at") SELECT "team_id", "uid", "role", "created_at", "updated_at" FROM `team_members`;--> statement-breakpoint
DROP TABLE `team_members`;--> statement-breakpoint
ALTER TABLE `__new_team_members` RENAME TO `team_members`;--> statement-breakpoint
CREATE INDEX `idx_team_members_uid_created` ON `team_members` (`uid`,`created_at`);
