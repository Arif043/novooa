-- Bestehende Dubletten bekommen die Notiz-ID angehängt; die älteste Notiz behält ihren Titel.
UPDATE `knowledge_notes` SET `title` = `title` || ' (' || `id` || ')'
WHERE EXISTS (
  SELECT 1 FROM `knowledge_notes` AS `older`
  WHERE `older`.`team_id` = `knowledge_notes`.`team_id`
    AND `older`.`knowledge_base_id` = `knowledge_notes`.`knowledge_base_id`
    AND `older`.`title` = `knowledge_notes`.`title` COLLATE NOCASE
    AND (`older`.`created_at` < `knowledge_notes`.`created_at`
      OR (`older`.`created_at` = `knowledge_notes`.`created_at` AND `older`.`id` < `knowledge_notes`.`id`))
);--> statement-breakpoint
CREATE UNIQUE INDEX `idx_notes_unique_title` ON `knowledge_notes` (`team_id`,`knowledge_base_id`,"title" COLLATE NOCASE);
