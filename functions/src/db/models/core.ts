import {sql} from "drizzle-orm";
import {check, index, integer, primaryKey, sqliteTable, text, unique, type AnySQLiteColumn} from "drizzle-orm/sqlite-core";

export const activities = sqliteTable("activities", {
  id: text("id").primaryKey(),
  team_id: text("team_id").notNull().references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  run_id: text("run_id").notNull(),
  task_id: text("task_id").notNull(),
  node_id: text("node_id"),
  target: text("target").notNull(),
  primitive: text("primitive"),
  title: text("title").notNull(),
  status: text("status").notNull(),
  input: text("input").notNull().default(""),
  output: text("output").notNull().default(""),
  outputs_json: text("outputs_json").notNull().default("{}"),
  message: text("message").notNull().default(""),
  duration_ms: integer("duration_ms"),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  console_json: text("console_json").notNull().default("{}"),
}, (table) => [
  index("idx_activities_team_run").on(table.team_id, table.run_id),
]);

export const taskRunJobs = sqliteTable("task_run_jobs", {
  id: text("id").primaryKey(),
  run_id: text("run_id").notNull().references((): AnySQLiteColumn => taskRuns.id, {onDelete: "cascade"}),
  mode: text("mode", {enum: ["start", "resume"]}).notNull(),
  status: text("status").notNull(),
  attempts: integer("attempts").notNull().default(0),
  available_at: text("available_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  lease_expires_at: text("lease_expires_at"),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [
  index("idx_task_run_jobs_next").on(table.status, table.available_at, table.lease_expires_at),
  check("task_run_jobs_mode", sql`${table.mode} IN ('start', 'resume')`),
  check("task_run_jobs_status", sql`${table.status} IN ('queued', 'leased', 'completed', 'failed')`),
  unique().on(table.run_id),
]);

export const taskRuns = sqliteTable("task_runs", {
  id: text("id").primaryKey(),
  team_id: text("team_id").notNull().references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  task_id: text("task_id").notNull(),
  task_title: text("task_title").notNull(),
  status: text("status").notNull(),
  context: text("context").notNull().default(""),
  input_json: text("input_json").notNull().default("{}"),
  final_output: text("final_output").notNull().default(""),
  resume_state_json: text("resume_state_json"),
  error_json: text("error_json"),
  source: text("source"),
  trigger_id: text("trigger_id"),
  trigger_type: text("trigger_type"),
  waiting_node_id: text("waiting_node_id"),
  review_instruction: text("review_instruction"),
  review_output: text("review_output"),
  approved_output: text("approved_output"),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  started_at: text("started_at"),
  completed_at: text("completed_at"),
  paused_at: text("paused_at"),
  reviewed_at: text("reviewed_at"),
  response_outputs_json: text("response_outputs_json"),
  interaction_json: text("interaction_json"),
}, (table) => [
  index("idx_task_runs_task_status").on(table.team_id, table.task_id, table.status),
  index("idx_task_runs_team_status").on(table.team_id, table.status),
]);

/** Ergebnisse abgeschlossener Baustein-Schritte; ein nach einem Absturz wiederholter Run übernimmt sie. */
export const taskRunSteps = sqliteTable("task_run_steps", {
  run_id: text("run_id").notNull().references((): AnySQLiteColumn => taskRuns.id, {onDelete: "cascade"}),
  step_path: text("step_path").notNull(),
  result_json: text("result_json").notNull(),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [
  primaryKey({columns: [table.run_id, table.step_path]}),
]);

export const taskTriggers = sqliteTable("task_triggers", {
  id: text("id").primaryKey(),
  task_id: text("task_id").notNull().references((): AnySQLiteColumn => tasks.id, {onDelete: "cascade"}),
  type: text("type").notNull(),
  enabled: integer("enabled").notNull().default(1),
  config_json: text("config_json").notNull().default("{}"),
  event_config_json: text("event_config_json").notNull().default("{}"),
  policy_json: text("policy_json").notNull().default("{}"),
  next_run_at: text("next_run_at"),
  last_run_at: text("last_run_at"),
  last_run_id: text("last_run_id"),
  created_by_uid: text("created_by_uid").notNull(),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [
  index("idx_task_triggers_task").on(table.task_id, table.enabled),
  index("idx_task_triggers_due").on(table.enabled, table.next_run_at),
]);

export const tasks = sqliteTable("tasks", {
  id: text("id").primaryKey(),
  team_id: text("team_id").notNull().references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  title: text("title").notNull(),
  objective: text("objective").notNull().default(""),
  graph_json: text("graph_json").notNull(),
  created_by_uid: text("created_by_uid").notNull(),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  selected_node_id: text("selected_node_id").notNull().default(""),
}, (table) => [
  index("idx_tasks_team_id").on(table.team_id),
]);

export const userProfiles = sqliteTable("user_profiles", {
  uid: text("uid").primaryKey(),
  email: text("email").notNull().default(""),
  display_name: text("display_name").notNull().default(""),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

export const teamMembers = sqliteTable("team_members", {
  team_id: text("team_id").notNull().references((): AnySQLiteColumn => teams.id, {onDelete: "cascade"}),
  uid: text("uid").notNull().references((): AnySQLiteColumn => userProfiles.uid, {onDelete: "cascade"}),
  role: text("role").notNull().default("member"),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
}, (table) => [
  primaryKey({columns: [table.team_id, table.uid]}),
  index("idx_team_members_uid_created").on(table.uid, table.created_at),
]);

export const teams = sqliteTable("teams", {
  id: text("id").primaryKey(),
  name: text("name").notNull(),
  owner_uid: text("owner_uid").notNull(),
  created_at: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updated_at: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`),
});

export type Activities = typeof activities.$inferSelect;
export type NewActivities = typeof activities.$inferInsert;
export type TaskRunJobs = typeof taskRunJobs.$inferSelect;
export type NewTaskRunJobs = typeof taskRunJobs.$inferInsert;
export type TaskRuns = typeof taskRuns.$inferSelect;
export type NewTaskRuns = typeof taskRuns.$inferInsert;
export type TaskTriggers = typeof taskTriggers.$inferSelect;
export type NewTaskTriggers = typeof taskTriggers.$inferInsert;
export type Tasks = typeof tasks.$inferSelect;
export type NewTasks = typeof tasks.$inferInsert;
export type TeamMembers = typeof teamMembers.$inferSelect;
export type NewTeamMembers = typeof teamMembers.$inferInsert;
export type Teams = typeof teams.$inferSelect;
export type NewTeams = typeof teams.$inferInsert;

export type UserProfiles = typeof userProfiles.$inferSelect;
export type NewUserProfiles = typeof userProfiles.$inferInsert;
