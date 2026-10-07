import {eq} from "drizzle-orm";
import {z} from "zod";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {knowledgeNotes} from "../../../../db/schema.js";
import {type TransferTeamMapping} from "../../domain/entities/transfer-team-mapping.js";
import {transferDataEntry, type TransferArchiveReader, type TransferArchiveWriter} from "../../domain/repositories/transfer-archive.js";
import {type TransferSection} from "../../domain/repositories/transfer-section.js";
import {sectionPayload, stagedRows, type SQLiteTransferSectionImporter, type StagedSectionImport} from "./sqlite-transfer-section-importer.js";

const timestamp = z.string().min(1).max(64);

const knowledgeTransferPayload = z.object({
  notes: z.array(z.object({
    id: z.string().min(1).max(200), knowledgeBaseId: z.string().min(1), title: z.string(), path: z.string(),
    type: z.string(), content: z.string(),
    createdAt: timestamp, updatedAt: timestamp,
  })),
});

type KnowledgeTransferPayload = z.infer<typeof knowledgeTransferPayload>;

export class SQLiteKnowledgeTransferSection implements TransferSection, SQLiteTransferSectionImporter {
  readonly category = "knowledge" as const;

  constructor(private readonly database: RuntimeExecutor) {}

  async exportTo(writer: TransferArchiveWriter, teamId: string): Promise<number> {
    const rows = await this.database.select().from(knowledgeNotes).where(eq(knowledgeNotes.team_id, teamId));
    const payload: KnowledgeTransferPayload = {
      notes: rows.map((row) => ({id: row.id, knowledgeBaseId: row.knowledge_base_id, title: row.title, path: row.path,
        type: row.type, content: row.content,
        createdAt: row.created_at, updatedAt: row.updated_at})),
    };
    await writer.addJson(transferDataEntry("knowledge"), payload);
    return payload.notes.length;
  }

  async stage(reader: TransferArchiveReader, mapping: TransferTeamMapping): Promise<StagedSectionImport> {
    const payload = await sectionPayload(reader, "knowledge", knowledgeTransferPayload);
    return stagedRows(payload.notes.length, (executor) => commitNotes(executor, payload, mapping));
  }
}

async function commitNotes(
  executor: RuntimeExecutor, payload: KnowledgeTransferPayload, mapping: TransferTeamMapping,
): Promise<void> {
  const teamId = mapping.targetTeamId;
  for (const note of payload.notes) {
    const values = {knowledge_base_id: note.knowledgeBaseId, title: note.title, path: note.path, type: note.type,
      content: mapping.references(note.content),
      updated_at: note.updatedAt};
    await executor.insert(knowledgeNotes).values({id: note.id, team_id: teamId, created_at: note.createdAt, ...values})
      .onConflictDoUpdate({target: knowledgeNotes.id, set: values, setWhere: eq(knowledgeNotes.team_id, teamId)});
  }
}
