CREATE TABLE `activities` (
	`id` text PRIMARY KEY NOT NULL,
	`team_id` text NOT NULL,
	`run_id` text NOT NULL,
	`task_id` text NOT NULL,
	`node_id` text,
	`target` text NOT NULL,
	`primitive` text,
	`title` text NOT NULL,
	`status` text NOT NULL,
	`input` text DEFAULT '' NOT NULL,
	`output` text DEFAULT '' NOT NULL,
	`outputs_json` text DEFAULT '{}' NOT NULL,
	`message` text DEFAULT '' NOT NULL,
	`duration_ms` integer,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `idx_activities_team_run` ON `activities` (`team_id`,`run_id`);--> statement-breakpoint
CREATE TABLE `task_run_jobs` (
	`id` text PRIMARY KEY NOT NULL,
	`team_id` text NOT NULL,
	`run_id` text NOT NULL,
	`mode` text NOT NULL,
	`status` text NOT NULL,
	`attempts` integer DEFAULT 0 NOT NULL,
	`available_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`lease_expires_at` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`run_id`) REFERENCES `task_runs`(`id`) ON UPDATE no action ON DELETE cascade,
	CONSTRAINT "task_run_jobs_mode" CHECK("task_run_jobs"."mode" IN ('start', 'resume')),
	CONSTRAINT "task_run_jobs_status" CHECK("task_run_jobs"."status" IN ('queued', 'leased', 'completed', 'failed'))
);
--> statement-breakpoint
CREATE INDEX `idx_task_run_jobs_next` ON `task_run_jobs` (`status`,`available_at`,`lease_expires_at`);--> statement-breakpoint
CREATE UNIQUE INDEX `task_run_jobs_team_id_run_id_unique` ON `task_run_jobs` (`team_id`,`run_id`);--> statement-breakpoint
CREATE TABLE `task_runs` (
	`id` text PRIMARY KEY NOT NULL,
	`team_id` text NOT NULL,
	`task_id` text NOT NULL,
	`task_title` text NOT NULL,
	`status` text NOT NULL,
	`context` text DEFAULT '' NOT NULL,
	`input_json` text DEFAULT '{}' NOT NULL,
	`final_output` text DEFAULT '' NOT NULL,
	`resume_state_json` text,
	`error_json` text,
	`source` text,
	`trigger_id` text,
	`trigger_type` text,
	`waiting_node_id` text,
	`review_instruction` text,
	`review_output` text,
	`approved_output` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`started_at` text,
	`completed_at` text,
	`paused_at` text,
	`reviewed_at` text,
	`response_outputs_json` text,
	`interaction_json` text,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `idx_task_runs_task_status` ON `task_runs` (`team_id`,`task_id`,`status`);--> statement-breakpoint
CREATE INDEX `idx_task_runs_team_status` ON `task_runs` (`team_id`,`status`);--> statement-breakpoint
CREATE TABLE `task_triggers` (
	`id` text PRIMARY KEY NOT NULL,
	`team_id` text NOT NULL,
	`task_id` text NOT NULL,
	`type` text NOT NULL,
	`enabled` integer DEFAULT 1 NOT NULL,
	`config_json` text DEFAULT '{}' NOT NULL,
	`event_config_json` text DEFAULT '{}' NOT NULL,
	`policy_json` text DEFAULT '{}' NOT NULL,
	`next_run_at` text,
	`last_run_at` text,
	`last_run_id` text,
	`created_by_uid` text NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `idx_task_triggers_team` ON `task_triggers` (`team_id`,`enabled`);--> statement-breakpoint
CREATE INDEX `idx_task_triggers_due` ON `task_triggers` (`enabled`,`next_run_at`);--> statement-breakpoint
CREATE TABLE `tasks` (
	`id` text PRIMARY KEY NOT NULL,
	`team_id` text NOT NULL,
	`title` text NOT NULL,
	`objective` text DEFAULT '' NOT NULL,
	`graph_json` text NOT NULL,
	`created_by_uid` text NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`selected_node_id` text DEFAULT '' NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `idx_tasks_team_id` ON `tasks` (`team_id`);--> statement-breakpoint
CREATE TABLE `team_members` (
	`team_id` text NOT NULL,
	`uid` text NOT NULL,
	`email` text DEFAULT '' NOT NULL,
	`display_name` text DEFAULT '' NOT NULL,
	`role` text DEFAULT 'member' NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	PRIMARY KEY(`team_id`, `uid`),
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `teams` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`owner_uid` text NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL
);
--> statement-breakpoint
CREATE TABLE `application_logs` (
	`id` text PRIMARY KEY NOT NULL,
	`team_id` text NOT NULL,
	`level` text NOT NULL,
	`event` text NOT NULL,
	`message` text,
	`data_json` text DEFAULT '{}' NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`source` text DEFAULT 'runtime' NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade,
	CONSTRAINT "application_logs_level" CHECK("application_logs"."level" IN ('info', 'error')),
	CONSTRAINT "application_logs_source" CHECK("application_logs"."source" IN ('client', 'runtime'))
);
--> statement-breakpoint
CREATE INDEX `idx_application_logs_team_created` ON `application_logs` (`team_id`,"created_at" desc);--> statement-breakpoint
CREATE TABLE `communication_channels` (
	`id` text PRIMARY KEY NOT NULL,
	`team_id` text NOT NULL,
	`kind` text NOT NULL,
	`display_name` text NOT NULL,
	`address` text NOT NULL,
	`provider` text DEFAULT 'novooaRelay' NOT NULL,
	`provider_ref` text,
	`status` text DEFAULT 'active' NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `idx_channels_team` ON `communication_channels` (`team_id`);--> statement-breakpoint
CREATE TABLE `inbound_channel_events` (
	`event_id` text PRIMARY KEY NOT NULL,
	`team_id` text NOT NULL,
	`connector_id` text NOT NULL,
	`provider` text NOT NULL,
	`provider_message_id` text NOT NULL,
	`event_json` text NOT NULL,
	`received_at` text NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `idx_inbound_channel_events_team_received` ON `inbound_channel_events` (`team_id`,"received_at" desc);--> statement-breakpoint
CREATE UNIQUE INDEX `inbound_channel_events_team_id_provider_provider_message_id_unique` ON `inbound_channel_events` (`team_id`,`provider`,`provider_message_id`);--> statement-breakpoint
CREATE TABLE `language_model_connections` (
	`id` text PRIMARY KEY NOT NULL,
	`team_id` text NOT NULL,
	`name` text NOT NULL,
	`provider` text NOT NULL,
	`base_url` text,
	`secret_ref` text NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `language_model_defaults` (
	`team_id` text PRIMARY KEY NOT NULL,
	`block_model_id` text,
	`assistant_model_id` text
);
--> statement-breakpoint
CREATE TABLE `language_model_secrets` (
	`secret_ref` text PRIMARY KEY NOT NULL,
	`encrypted_value` text NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL
);
--> statement-breakpoint
CREATE TABLE `language_models` (
	`id` text PRIMARY KEY NOT NULL,
	`team_id` text NOT NULL,
	`connection_id` text NOT NULL,
	`name` text NOT NULL,
	`model_id` text NOT NULL,
	`capabilities_json` text DEFAULT '{}' NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`connection_id`) REFERENCES `language_model_connections`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `language_models_team_id_idx` ON `language_models` (`team_id`);--> statement-breakpoint
CREATE TABLE `model_catalog` (
	`id` text PRIMARY KEY NOT NULL,
	`title` text NOT NULL,
	`description` text NOT NULL,
	`tags_json` text DEFAULT '[]' NOT NULL,
	`scope` text NOT NULL,
	`team_id` text,
	`runtime` text NOT NULL,
	`artifact_reference_json` text NOT NULL,
	`contract_json` text NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade,
	CONSTRAINT "model_catalog_scope" CHECK("model_catalog"."scope" IN ('system', 'team')),
	CONSTRAINT "model_catalog_runtime" CHECK("model_catalog"."runtime" = 'onnx'),
	CONSTRAINT "model_catalog_team_scope" CHECK(("model_catalog"."scope" = 'system' AND "model_catalog"."team_id" IS NULL) OR ("model_catalog"."scope" = 'team' AND "model_catalog"."team_id" IS NOT NULL))
);
--> statement-breakpoint
CREATE INDEX `idx_model_catalog_scope_team` ON `model_catalog` (`scope`,`team_id`);--> statement-breakpoint
CREATE TABLE `runtime_access_credential` (
	`id` integer PRIMARY KEY NOT NULL,
	`password_hash` text NOT NULL,
	`salt` text NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT "runtime_access_credential_singleton" CHECK("runtime_access_credential"."id" = 1)
);
--> statement-breakpoint
CREATE TABLE `runtime_sessions` (
	`token_hash` text PRIMARY KEY NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`expires_at` text NOT NULL
);
--> statement-breakpoint
CREATE TABLE `document_collections` (
	`id` text NOT NULL,
	`team_id` text NOT NULL,
	`display_name` text NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	PRIMARY KEY(`team_id`, `id`),
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `idx_document_collections_team_display_name` ON `document_collections` (`team_id`,`display_name`);--> statement-breakpoint
CREATE TABLE `documents` (
	`id` text NOT NULL,
	`team_id` text NOT NULL,
	`collection_id` text NOT NULL,
	`data_json` text NOT NULL,
	`version` integer DEFAULT 1 NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	PRIMARY KEY(`team_id`, `collection_id`, `id`),
	FOREIGN KEY (`team_id`,`collection_id`) REFERENCES `document_collections`(`team_id`,`id`) ON UPDATE no action ON DELETE cascade,
	CONSTRAINT "documents_json_object" CHECK(json_valid("documents"."data_json") AND json_type("documents"."data_json") = 'object'),
	CONSTRAINT "documents_positive_version" CHECK("documents"."version" > 0)
);
--> statement-breakpoint
CREATE INDEX `idx_documents_team_collection_updated` ON `documents` (`team_id`,`collection_id`,"updated_at" desc,`id`);--> statement-breakpoint
CREATE TABLE `file_folders` (
	`id` text PRIMARY KEY NOT NULL,
	`team_id` text NOT NULL,
	`owner_uid` text NOT NULL,
	`name` text NOT NULL,
	`parent_folder_id` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`parent_folder_id`) REFERENCES `file_folders`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `idx_file_folders_team_parent` ON `file_folders` (`team_id`,`parent_folder_id`);--> statement-breakpoint
CREATE TABLE `file_versions` (
	`id` text PRIMARY KEY NOT NULL,
	`team_id` text NOT NULL,
	`file_id` text NOT NULL,
	`created_by_uid` text NOT NULL,
	`display_name` text NOT NULL,
	`storage_path` text NOT NULL,
	`content_type` text DEFAULT 'application/octet-stream' NOT NULL,
	`size_bytes` integer DEFAULT 0 NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`file_id`) REFERENCES `files`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `files` (
	`id` text PRIMARY KEY NOT NULL,
	`team_id` text NOT NULL,
	`owner_uid` text NOT NULL,
	`display_name` text NOT NULL,
	`folder_id` text,
	`current_version_id` text,
	`content_type` text DEFAULT 'application/octet-stream' NOT NULL,
	`size_bytes` integer DEFAULT 0 NOT NULL,
	`storage_path` text NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `idx_files_team_folder` ON `files` (`team_id`,`folder_id`);--> statement-breakpoint
CREATE TABLE `knowledge_notes` (
	`id` text PRIMARY KEY NOT NULL,
	`team_id` text NOT NULL,
	`knowledge_base_id` text DEFAULT 'default' NOT NULL,
	`title` text NOT NULL,
	`path` text DEFAULT '' NOT NULL,
	`type` text DEFAULT 'unknown' NOT NULL,
	`content` text DEFAULT '' NOT NULL,
	`outgoing_links_json` text DEFAULT '[]' NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`team_id`) REFERENCES `teams`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `idx_notes_team_base` ON `knowledge_notes` (`team_id`,`knowledge_base_id`);