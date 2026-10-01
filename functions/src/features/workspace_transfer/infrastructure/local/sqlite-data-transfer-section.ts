import {and, eq} from "drizzle-orm";
import {z} from "zod";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {documentCollections, documents} from "../../../../db/schema.js";
import {type TransferTeamMapping} from "../../domain/entities/transfer-team-mapping.js";
import {transferDataEntry, type TransferArchiveReader, type TransferArchiveWriter} from "../../domain/repositories/transfer-archive.js";
import {type TransferSection} from "../../domain/repositories/transfer-section.js";
import {sectionPayload, stagedRows, type SqliteTransferSectionImporter, type StagedSectionImport} from "./sqlite-transfer-section-importer.js";

const id = z.string().min(1).max(200);
const timestamp = z.string().min(1).max(64);

const dataTransferPayload = z.object({
  collections: z.array(z.object({id, displayName: z.string().min(1), createdAt: timestamp, updatedAt: timestamp})),
  documents: z.array(z.object({
    id, collectionId: id, data: z.record(z.string(), z.unknown()), version: z.number().int().positive(),
    createdAt: timestamp, updatedAt: timestamp,
  })),
});

type DataTransferPayload = z.infer<typeof dataTransferPayload>;
type DocumentDto = DataTransferPayload["documents"][number];

export class SqliteDataTransferSection implements TransferSection, SqliteTransferSectionImporter {
  readonly category = "data" as const;

  constructor(private readonly database: RuntimeExecutor) {}

  async exportTo(writer: TransferArchiveWriter, teamId: string): Promise<number> {
    const collections = await this.database.select().from(documentCollections).where(eq(documentCollections.team_id, teamId));
    const rows = await this.database.select().from(documents).where(eq(documents.team_id, teamId));
    const payload: DataTransferPayload = {
      collections: collections.map((row) => ({id: row.id, displayName: row.display_name,
        createdAt: row.created_at, updatedAt: row.updated_at})),
      documents: rows.map((row) => ({id: row.id, collectionId: row.collection_id, data: JSON.parse(row.data_json),
        version: row.version, createdAt: row.created_at, updatedAt: row.updated_at})),
    };
    await writer.addJson(transferDataEntry("data"), payload);
    return payload.documents.length;
  }

  async stage(reader: TransferArchiveReader, mapping: TransferTeamMapping): Promise<StagedSectionImport> {
    const payload = await sectionPayload(reader, "data", dataTransferPayload);
    return stagedRows(payload.documents.length, (executor) => commitData(executor, payload, mapping.targetTeamId));
  }
}

async function commitData(executor: RuntimeExecutor, payload: DataTransferPayload, teamId: string): Promise<void> {
  const collectionIds = await targetCollectionIds(executor, payload, teamId);
  for (const collection of payload.collections) {
    const targetId = collectionIds.get(collection.id) as string;
    await executor.insert(documentCollections).values({id: targetId, team_id: teamId, display_name: collection.displayName,
      created_at: collection.createdAt, updated_at: collection.updatedAt})
      .onConflictDoUpdate({target: [documentCollections.team_id, documentCollections.id],
        set: {display_name: collection.displayName, updated_at: collection.updatedAt}});
  }
  for (const document of payload.documents) {
    await upsertDocument(executor, teamId, document, collectionIds.get(document.collectionId) ?? document.collectionId);
  }
}

/**
 * Collection-Namen sind pro Team eindeutig. Existiert bereits eine Collection
 * mit gleichem Namen, werden die importierten Datensätze in diese übernommen.
 */
async function targetCollectionIds(
  executor: RuntimeExecutor, payload: DataTransferPayload, teamId: string,
): Promise<Map<string, string>> {
  const existing = await executor.select({id: documentCollections.id, name: documentCollections.display_name})
    .from(documentCollections).where(eq(documentCollections.team_id, teamId));
  const idByName = new Map(existing.map((row) => [row.name, row.id]));
  return new Map(payload.collections.map((collection) => [
    collection.id, idByName.get(collection.displayName) ?? collection.id,
  ]));
}

async function upsertDocument(
  executor: RuntimeExecutor, teamId: string, document: DocumentDto, collectionId: string,
): Promise<void> {
  const values = {data_json: JSON.stringify(document.data), version: document.version, updated_at: document.updatedAt};
  await executor.insert(documents).values({id: document.id, team_id: teamId, collection_id: collectionId,
    created_at: document.createdAt, ...values})
    .onConflictDoUpdate({target: [documents.team_id, documents.collection_id, documents.id], set: values,
      setWhere: and(eq(documents.team_id, teamId), eq(documents.collection_id, collectionId))});
}
