import {eq} from "drizzle-orm";
import {createWriteStream} from "node:fs";
import {mkdtemp, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import {finished} from "node:stream/promises";
import {type TestContext} from "node:test";
import {type RuntimeDatabase} from "../../../../db/database.js";
import {documentCollections, documents, fileFolders, files, fileVersions, knowledgeNotes, tasks} from "../../../../db/schema.js";
import {writeLocalFile} from "../../../files/infrastructure/local/local-file-path.js";
import {TransferCategorySelection, type TransferCategory} from "../../domain/entities/transfer-category.js";
import {ExportWorkspace} from "../../domain/usecases/export-workspace.js";
import {FflateTransferArchiveWriter} from "../zip/fflate-transfer-archive-writer.js";
import {SqliteDataTransferSection} from "./sqlite-data-transfer-section.js";
import {SqliteFilesTransferSection} from "./sqlite-files-transfer-section.js";
import {SqliteKnowledgeTransferSection} from "./sqlite-knowledge-transfer-section.js";
import {SqliteTasksTransferSection} from "./sqlite-tasks-transfer-section.js";

/** Nur Tests. */
export async function temporaryDirectory(t: TestContext): Promise<string> {
  const directory = await mkdtemp(path.join(os.tmpdir(), "novooa-transfer-"));
  t.after(() => rm(directory, {recursive: true, force: true}));
  return directory;
}

export const sampleStoragePath = "teams/team-1/files/file-1/versions/version-1/angebot.txt";

export async function seedWorkspace(database: RuntimeDatabase, runtimeRoot: string): Promise<void> {
  await database.insert(fileFolders).values([
    {id: "folder-child", owner_uid: "user-1", name: "Kind", parent_folder_id: "folder-root"},
    {id: "folder-root", root_team_id: "team-1", owner_uid: "user-1", name: "Wurzel", parent_folder_id: null},
  ].reverse());
  await database.insert(files).values({id: "file-1", owner_uid: "user-1", display_name: "angebot.txt",
    folder_id: "folder-child"});
  await database.insert(fileVersions).values({id: "version-1", file_id: "file-1",
    created_by_uid: "user-1", display_name: "angebot.txt", storage_path: sampleStoragePath, content_type: "text/plain",
    size_bytes: 5});
  await database.update(files).set({current_version_id: "version-1"}).where(eq(files.id, "file-1"));
  await writeLocalFile(runtimeRoot, sampleStoragePath, "Hallo");
  await database.insert(documentCollections).values({id: "collection-1", team_id: "team-1", display_name: "Kunden"});
  await database.insert(documents).values({id: "doc-1", team_id: "team-1", collection_id: "collection-1",
    data_json: JSON.stringify({name: "ACME"})});
  await database.insert(knowledgeNotes).values({id: "note-1", team_id: "team-1", title: "Leitfaden",
    content: "# Leitfaden", outgoing_links_json: "[]"});
  await database.insert(tasks).values({id: "task-1", team_id: "team-1", title: "Angebot prüfen",
    graph_json: JSON.stringify({nodes: [{attachments: [{storagePath: sampleStoragePath}]}]}), created_by_uid: "user-1"});
}

export async function exportArchive(
  database: RuntimeDatabase, runtimeRoot: string, categories: TransferCategory[], archivePath: string,
): Promise<void> {
  const writer = new FflateTransferArchiveWriter();
  const written = finished(writer.output.pipe(createWriteStream(archivePath)));
  const exportWorkspace = new ExportWorkspace([
    new SqliteFilesTransferSection(database, runtimeRoot), new SqliteDataTransferSection(database),
    new SqliteKnowledgeTransferSection(database), new SqliteTasksTransferSection(database),
  ]);
  await exportWorkspace.execute({teamId: "team-1", selection: TransferCategorySelection.from(categories), writer});
  writer.finish();
  await written;
}
