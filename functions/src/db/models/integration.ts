import {desc, sql} from "drizzle-orm";
import {check, index, integer, sqliteTable, text, unique, type AnySQLiteColumn} from "drizzle-orm/sqlite-core";
import {teams} from "./core.js";

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
  team_id: text("team_id").notNull().references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  connection_id: text("connection_id").notNull().references((): AnySQLiteColumn => languageModelConnections.id, {onDelete: "cascade"}),
  name: text("name").notNull(),
  model_id: text("model_id").notNull(),
  capabilities_json: text("capabilities_json").notNull().default("{}"),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [
  index("language_models_team_id_idx").on(table.team_id),
]);

export const modelCatalog = sqliteTable("model_catalog", {
  id: text("id").primaryKey(),
  title: text("title").notNull(),
  description: text("description").notNull(),
  translations_json: text("translations_json").notNull().default("{}"),
  tags_json: text("tags_json").notNull().default("[]"),
  scope: text("scope").notNull(),
  team_id: text("team_id").references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  runtime: text("runtime").notNull(),
  artifact_reference_json: text("artifact_reference_json").notNull(),
  contract_json: text("contract_json").notNull(),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [
  index("idx_model_catalog_scope_team").on(table.scope, table.team_id),
  check("model_catalog_scope", sql`${table.scope} IN ('system', 'team')`),
  check("model_catalog_runtime", sql`${table.runtime} = 'onnx'`),
  check("model_catalog_team_scope", sql`(${table.scope} = 'system' AND ${table.team_id} IS NULL) OR (${table.scope} = 'team' AND ${table.team_id} IS NOT NULL)`),
]);

export const runtimeAccessCredential = sqliteTable("runtime_access_credential", {
  id: integer("id").primaryKey(),
  password_hash: text("password_hash").notNull(),
  salt: text("salt").notNull(),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [check("runtime_access_credential_singleton", sql`${table.id} = 1`)]);

export const runtimeSessions = sqliteTable("runtime_sessions", {
  token_hash: text("token_hash").primaryKey(),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  expires_at: text("expires_at").notNull(),
});

export type ApplicationLogs = typeof applicationLogs.$inferSelect;
export type NewApplicationLogs = typeof applicationLogs.$inferInsert;
export type CommunicationChannels = typeof communicationChannels.$inferSelect;
export type NewCommunicationChannels = typeof communicationChannels.$inferInsert;
export type InboundChannelEvents = typeof inboundChannelEvents.$inferSelect;
export type NewInboundChannelEvents = typeof inboundChannelEvents.$inferInsert;
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
export type RuntimeAccessCredential = typeof runtimeAccessCredential.$inferSelect;
export type NewRuntimeAccessCredential = typeof runtimeAccessCredential.$inferInsert;
export type RuntimeSessions = typeof runtimeSessions.$inferSelect;
export type NewRuntimeSessions = typeof runtimeSessions.$inferInsert;
