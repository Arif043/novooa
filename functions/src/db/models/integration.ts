import {desc, sql} from "drizzle-orm";
import {check, index, sqliteTable, text, unique, uniqueIndex, type AnySQLiteColumn} from "drizzle-orm/sqlite-core";
import {teams, userProfiles} from "./core.js";

export const applicationLogs = sqliteTable("application_logs", {
  id: text("id").primaryKey(),
  team_id: text("team_id").notNull().references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  level: text("level", {enum: ["info", "error"]}).notNull(),
  event: text("event").notNull(),
  message: text("message"),
  data_json: text("data_json").notNull().default("{}"),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  source: text("source", {enum: ["client", "runtime"]}).notNull().default("runtime"),
}, (table) => [
  index("idx_application_logs_team_created").on(table.team_id, desc(table.created_at)),
  check("application_logs_level", sql`${table.level} IN ('info', 'error')`),
  check("application_logs_source", sql`${table.source} IN ('client', 'runtime')`),
]);

export const connections = sqliteTable("connections", {
  id: text("id").primaryKey(),
  team_id: text("team_id").notNull().references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  name: text("name").notNull(),
  base_url: text("base_url").notNull(),
  auth_json: text("auth_json").notNull(),
  secret_ref: text("secret_ref").notNull(),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [
  index("idx_connections_team").on(table.team_id),
]);

export const communicationChannels = sqliteTable("communication_channels", {
  id: text("id").primaryKey(),
  team_id: text("team_id").notNull().references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  kind: text("kind").notNull(),
  display_name: text("display_name").notNull(),
  address: text("address").notNull(),
  provider: text("provider").notNull().default("novooaRelay"),
  provider_ref: text("provider_ref"),
  status: text("status").notNull().default("active"),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [
  index("idx_channels_team").on(table.team_id),
]);

export const inboundChannelEvents = sqliteTable("inbound_channel_events", {
  event_id: text("event_id").primaryKey(),
  team_id: text("team_id").notNull().references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  connector_id: text("connector_id").notNull(),
  provider: text("provider").notNull(),
  provider_message_id: text("provider_message_id").notNull(),
  event_json: text("event_json").notNull(),
  received_at: text("received_at").notNull(),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [
  index("idx_inbound_channel_events_team_received").on(table.team_id, desc(table.received_at)),
  unique().on(table.team_id, table.provider, table.provider_message_id),
]);

export const languageModelConnections = sqliteTable("language_model_connections", {
  id: text("id").primaryKey(),
  team_id: text("team_id").notNull().references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  name: text("name").notNull(),
  provider: text("provider").notNull(),
  base_url: text("base_url"),
  secret_ref: text("secret_ref").notNull(),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

export const languageModelDefaults = sqliteTable("language_model_defaults", {
  team_id: text("team_id").primaryKey(),
  block_model_id: text("block_model_id"),
  knowledge_assistant_model_id: text("knowledge_assistant_model_id"),
});

export const languageModelSecrets = sqliteTable("language_model_secrets", {
  secret_ref: text("secret_ref").primaryKey(),
  encrypted_value: text("encrypted_value").notNull(),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

export const languageModels = sqliteTable("language_models", {
  id: text("id").primaryKey(),
  connection_id: text("connection_id").notNull().references((): AnySQLiteColumn => languageModelConnections.id, {onDelete: "cascade"}),
  name: text("name").notNull(),
  model_id: text("model_id").notNull(),
  capabilities_json: text("capabilities_json").notNull().default("{}"),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [
  index("language_models_connection_id_idx").on(table.connection_id),
]);

export const modelCatalog = sqliteTable("model_catalog", {
  id: text("id").primaryKey(),
  title: text("title").notNull(),
  description: text("description").notNull(),
  translations_json: text("translations_json").notNull().default("{}"),
  tags_json: text("tags_json").notNull().default("[]"),
  /** Was das Modell löst (Vokabular in `model-task.ts`); Alt-Einträge: `other`. */
  task: text("task").notNull().default("other"),
  languages_json: text("languages_json").notNull().default("[]"),
  team_id: text("team_id").references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  artifact_reference_json: text("artifact_reference_json").notNull(),
  contract_json: text("contract_json").notNull(),
  /** `catalog`: aus dem globalen Katalog gecacht, `import`: selbst importiert. */
  origin: text("origin", {enum: ["catalog", "import"]}).notNull().default("import"),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [
  index("idx_model_catalog_team").on(table.team_id),
]);

/** Spiegel des globalen Tag-Vokabulars (`modelTags`), damit Suche und Import auch ohne Firebase-Sitzung funktionieren. */
export const modelTags = sqliteTable("model_tags", {
  key: text("key").primaryKey(),
  parent: text("parent"),
  labels_json: text("labels_json").notNull(),
  synonyms_json: text("synonyms_json").notNull().default("{}"),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

/** Passwörter der Konten: scrypt-Hash, mit dem Master-Key verschlüsselt (siehe `passwordHashContext`). Getrennt vom Profil, damit ein Konto künftig per SSO auch ohne Passwort bestehen kann. */
export const runtimePasswordCredentials = sqliteTable("runtime_password_credentials", {
  uid: text("uid").primaryKey().references((): AnySQLiteColumn => userProfiles.uid, {onDelete: "cascade"}),
  encrypted_hash: text("encrypted_hash").notNull(),
  salt: text("salt").notNull(),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

/** Einmalcodes zum Setzen des Passworts (Einladung oder Zurücksetzen); gespeichert nur als SHA-256-Hash. */
export const runtimeInvitations = sqliteTable("runtime_invitations", {
  code_hash: text("code_hash").primaryKey(),
  uid: text("uid").notNull().references((): AnySQLiteColumn => userProfiles.uid, {onDelete: "cascade"}),
  expires_at: text("expires_at").notNull(),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [index("idx_runtime_invitations_uid").on(table.uid)]);

/** `id` ist die öffentliche Kennung zum einzelnen Abmelden; das Token selbst wird nur als Hash gespeichert. */
export const runtimeSessions = sqliteTable("runtime_sessions", {
  token_hash: text("token_hash").primaryKey(),
  id: text("id").notNull(),
  uid: text("uid").notNull().references((): AnySQLiteColumn => userProfiles.uid, {onDelete: "cascade"}),
  device_app: text("device_app").notNull().default(""),
  device_os: text("device_os").notNull().default("unknown"),
  device_browser: text("device_browser"),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  last_used_at: text("last_used_at").notNull(),
  expires_at: text("expires_at").notNull(),
}, (table) => [
  index("idx_runtime_sessions_uid").on(table.uid),
  uniqueIndex("idx_runtime_sessions_id").on(table.id),
]);

export type ApplicationLogs = typeof applicationLogs.$inferSelect;
export type NewApplicationLogs = typeof applicationLogs.$inferInsert;
export type CommunicationChannels = typeof communicationChannels.$inferSelect;
export type NewCommunicationChannels = typeof communicationChannels.$inferInsert;
export type InboundChannelEvents = typeof inboundChannelEvents.$inferSelect;
export type NewInboundChannelEvents = typeof inboundChannelEvents.$inferInsert;
export type Connections = typeof connections.$inferSelect;
export type LanguageModelConnections = typeof languageModelConnections.$inferSelect;
export type NewLanguageModelConnections = typeof languageModelConnections.$inferInsert;
export type LanguageModelDefaults = typeof languageModelDefaults.$inferSelect;
export type NewLanguageModelDefaults = typeof languageModelDefaults.$inferInsert;
export type LanguageModelSecrets = typeof languageModelSecrets.$inferSelect;
export type NewLanguageModelSecrets = typeof languageModelSecrets.$inferInsert;
export type LanguageModels = typeof languageModels.$inferSelect;
export type NewLanguageModels = typeof languageModels.$inferInsert;
export type ModelCatalog = typeof modelCatalog.$inferSelect;
export type NewModelCatalog = typeof modelCatalog.$inferInsert;
export type RuntimeSessions = typeof runtimeSessions.$inferSelect;
export type NewRuntimeSessions = typeof runtimeSessions.$inferInsert;
