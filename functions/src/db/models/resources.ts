import {desc, sql} from "drizzle-orm";
import {check, foreignKey, index, integer, primaryKey, sqliteTable, text, uniqueIndex, type AnySQLiteColumn} from "drizzle-orm/sqlite-core";
import {teams} from "./core.js";

export const documentCollections = sqliteTable("document_collections", {
  id: text("id").notNull(),
  team_id: text("team_id").notNull().references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  display_name: text("display_name").notNull(),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [
  primaryKey({columns: [table.team_id, table.id]}),
  uniqueIndex("idx_document_collections_team_display_name").on(table.team_id, table.display_name),
]);

export const documents = sqliteTable("documents", {
  id: text("id").notNull(),
  team_id: text("team_id").notNull(),
  collection_id: text("collection_id").notNull(),
  data_json: text("data_json").notNull(),
  version: integer("version").notNull().default(1),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [
  primaryKey({columns: [table.team_id, table.collection_id, table.id]}),
  index("idx_documents_team_collection_updated").on(table.team_id, table.collection_id, desc(table.updated_at), table.id),
  check("documents_json_object", sql`json_valid(${table.data_json}) AND json_type(${table.data_json}) = 'object'`),
  check("documents_positive_version", sql`${table.version} > 0`),
  foreignKey({columns: [table.team_id, table.collection_id], foreignColumns: [documentCollections.team_id, documentCollections.id]}).onDelete("cascade"),
]);

export const fileFolders = sqliteTable("file_folders", {
  id: text("id").primaryKey(),
  root_team_id: text("root_team_id").references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  owner_uid: text("owner_uid").notNull(),
  name: text("name").notNull(),
  parent_folder_id: text("parent_folder_id"),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [
  index("idx_file_folders_root_team").on(table.root_team_id),
  index("idx_file_folders_parent").on(table.parent_folder_id),
  check("file_folders_one_location", sql`(${table.parent_folder_id} IS NULL AND ${table.root_team_id} IS NOT NULL) OR
    (${table.parent_folder_id} IS NOT NULL AND ${table.root_team_id} IS NULL)`),
  check("file_folders_not_self_parent", sql`${table.parent_folder_id} IS NULL OR ${table.parent_folder_id} <> ${table.id}`),
  foreignKey((): {columns: [AnySQLiteColumn]; foreignColumns: [AnySQLiteColumn]} => ({columns: [table.parent_folder_id],
    foreignColumns: [fileFolders.id]})).onDelete("cascade"),
]);

export const workspaceFileSettings = sqliteTable("workspace_file_settings", {
  team_id: text("team_id").primaryKey().references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  version_limit: integer("version_limit").notNull(),
});

export const fileVersions = sqliteTable("file_versions", {
  id: text("id").primaryKey(),
  file_id: text("file_id").notNull().references((): AnySQLiteColumn => files.id, {onDelete: "cascade"}),
  created_by_uid: text("created_by_uid").notNull(),
  display_name: text("display_name").notNull(),
  storage_path: text("storage_path").notNull(),
  content_type: text("content_type").notNull().default("application/octet-stream"),
  size_bytes: integer("size_bytes").notNull().default(0),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [
  uniqueIndex("idx_file_versions_file_id_id").on(table.file_id, table.id),
  check("file_versions_nonnegative_size", sql`${table.size_bytes} >= 0`),
]);

export const files = sqliteTable("files", {
  id: text("id").primaryKey(),
  root_team_id: text("root_team_id").references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  owner_uid: text("owner_uid").notNull(),
  display_name: text("display_name").notNull(),
  folder_id: text("folder_id"),
  current_version_id: text("current_version_id"),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [
  index("idx_files_root_team").on(table.root_team_id),
  index("idx_files_folder").on(table.folder_id),
  check("files_one_location", sql`(${table.folder_id} IS NULL AND ${table.root_team_id} IS NOT NULL) OR
    (${table.folder_id} IS NOT NULL AND ${table.root_team_id} IS NULL)`),
  foreignKey({columns: [table.folder_id], foreignColumns: [fileFolders.id]}),
  foreignKey(() => ({columns: [table.id, table.current_version_id],
    foreignColumns: [fileVersions.file_id, fileVersions.id]})),
]);

export const knowledgeNotes = sqliteTable("knowledge_notes", {
  id: text("id").primaryKey(),
  team_id: text("team_id").notNull().references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  knowledge_base_id: text("knowledge_base_id").notNull().default("default"),
  title: text("title").notNull(),
  path: text("path").notNull().default(""),
  type: text("type").notNull().default("unknown"),
  content: text("content").notNull().default(""),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [
  index("idx_notes_team_base").on(table.team_id, table.knowledge_base_id),
  // Titel sind eindeutig, weil [[Titel]]-Links und Workspace-Dateinamen sie als Schlüssel nutzen.
  uniqueIndex("idx_notes_unique_title").on(table.team_id, table.knowledge_base_id, sql`${table.title} COLLATE NOCASE`),
]);

/** Mitarbeiter (Subagenten): Rahmenbedingung (= System-Prompt) plus Skill-Namen. */
export const employees = sqliteTable("employees", {
  id: text("id").primaryKey(),
  team_id: text("team_id").notNull().references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  name: text("name").notNull(),
  constraint_text: text("constraint_text").notNull().default(""),
  skills_json: text("skills_json").notNull().default("[]"),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [
  index("idx_employees_team_name").on(table.team_id, table.name),
]);

export type DocumentCollections = typeof documentCollections.$inferSelect;
export type NewDocumentCollections = typeof documentCollections.$inferInsert;
export type Documents = typeof documents.$inferSelect;
export type NewDocuments = typeof documents.$inferInsert;
export type FileFolders = typeof fileFolders.$inferSelect;
export type NewFileFolders = typeof fileFolders.$inferInsert;
export type FileVersions = typeof fileVersions.$inferSelect;
export type NewFileVersions = typeof fileVersions.$inferInsert;
export type Files = typeof files.$inferSelect;
export type NewFiles = typeof files.$inferInsert;
export type Employees = typeof employees.$inferSelect;
export type NewEmployees = typeof employees.$inferInsert;
export type KnowledgeNotes = typeof knowledgeNotes.$inferSelect;
export type NewKnowledgeNotes = typeof knowledgeNotes.$inferInsert;

/** Aktivierte Plugins je Arbeitsbereich; ohne Zeile ist ein Plugin aus. */
export const workspacePlugins = sqliteTable("workspace_plugins", {
  team_id: text("team_id").notNull().references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  plugin_id: text("plugin_id").notNull(),
  enabled_at: text("enabled_at").notNull(),
  enabled_by_uid: text("enabled_by_uid"),
}, (table) => [primaryKey({columns: [table.team_id, table.plugin_id]})]);
