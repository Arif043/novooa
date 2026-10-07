import {eq} from "drizzle-orm";
import {z} from "zod";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {tasks} from "../../../../db/schema.js";
import {type TransferTeamMapping} from "../../domain/entities/transfer-team-mapping.js";
import {transferDataEntry, type TransferArchiveReader, type TransferArchiveWriter} from "../../domain/repositories/transfer-archive.js";
import {type TransferSection} from "../../domain/repositories/transfer-section.js";
import {sectionPayload, stagedRows, type SQLiteTransferSectionImporter, type StagedSectionImport} from "./sqlite-transfer-section-importer.js";

const timestamp = z.string().min(1).max(64);

const tasksTransferPayload = z.object({
  tasks: z.array(z.object({
    id: z.string().min(1).max(200), title: z.string(), objective: z.string(),
    graph: z.record(z.string(), z.unknown()), selectedNodeId: z.string(), createdByUid: z.string(),
    createdAt: timestamp, updatedAt: timestamp,
  })),
});

type TasksTransferPayload = z.infer<typeof tasksTransferPayload>;

/** Trigger gehören bewusst nicht dazu: Sie können an OAuth-Connectoren gebunden sein. */
export class SQLiteTasksTransferSection implements TransferSection, SQLiteTransferSectionImporter {
  readonly category = "tasks" as const;

  constructor(private readonly database: RuntimeExecutor) {}

  async exportTo(writer: TransferArchiveWriter, teamId: string): Promise<number> {
    const rows = await this.database.select().from(tasks).where(eq(tasks.team_id, teamId));
    const payload: TasksTransferPayload = {
      tasks: rows.map((row) => ({id: row.id, title: row.title, objective: row.objective,
        graph: JSON.parse(row.graph_json) as Record<string, unknown>, selectedNodeId: row.selected_node_id,
        createdByUid: row.created_by_uid, createdAt: row.created_at, updatedAt: row.updated_at})),
    };
    await writer.addJson(transferDataEntry("tasks"), payload);
    return payload.tasks.length;
  }

  async stage(reader: TransferArchiveReader, mapping: TransferTeamMapping): Promise<StagedSectionImport> {
    const payload = await sectionPayload(reader, "tasks", tasksTransferPayload);
    return stagedRows(payload.tasks.length, (executor) => commitTasks(executor, payload, mapping));
  }
}

async function commitTasks(
  executor: RuntimeExecutor, payload: TasksTransferPayload, mapping: TransferTeamMapping,
): Promise<void> {
  const teamId = mapping.targetTeamId;
  for (const task of payload.tasks) {
    const values = {title: task.title, objective: task.objective,
      graph_json: mapping.references(JSON.stringify(task.graph)), selected_node_id: task.selectedNodeId,
      created_by_uid: task.createdByUid, updated_at: task.updatedAt};
    await executor.insert(tasks).values({id: task.id, team_id: teamId, created_at: task.createdAt, ...values})
      .onConflictDoUpdate({target: tasks.id, set: values, setWhere: eq(tasks.team_id, teamId)});
  }
}
