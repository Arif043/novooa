import assert from "node:assert/strict";
import path from "node:path";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {knowledgeNotes, teams} from "../../../../db/schema.js";
import {SQLiteKnowledgeBaseStore} from "../../../knowledge_base/infrastructure/local/sqlite-knowledge-base-store.js";
import {TransferCategorySelection} from "../../domain/entities/transfer-category.js";
import {ImportWorkspace} from "../../domain/usecases/import-workspace.js";
import {InspectWorkspaceImport} from "../../domain/usecases/inspect-workspace-import.js";
import {FflateTransferArchiveReader} from "../zip/fflate-transfer-archive-reader.js";
import {SqliteKnowledgeTransferSection} from "./sqlite-knowledge-transfer-section.js";
import {SqliteTransferImportStore} from "./sqlite-transfer-import-store.js";
import {exportArchive, temporaryDirectory} from "./workspace-transfer-test-support.js";

async function exportedKnowledge(t: TestContext) {
  const source = await runtimeTestDatabase(t);
  await source.insert(knowledgeNotes).values([
    {id: "source", team_id: "team-1", title: "Index", content: "[[Ziel]]"},
    {id: "target", team_id: "team-1", title: "Ziel", path: "ziel.md"},
  ]);
  const directory = await temporaryDirectory(t);
  const archivePath = path.join(directory, "knowledge.zip");
  await exportArchive(source, directory, ["knowledge"], archivePath);
  const reader = new FflateTransferArchiveReader(archivePath);
  return reader;
}

test("knowledge exports contain only authoritative fields and derive links after importing all notes", async (t) => {
  const reader = await exportedKnowledge(t);
  const payload = await reader.json("data/knowledge.json") as {notes: Array<Record<string, unknown>>};
  assert.ok(payload.notes.every((note) => !("outgoingLinks" in note)));
  const target = await runtimeTestDatabase(t);
  await target.insert(teams).values({id: "team-2", name: "Ziel", owner_uid: "u"});
  const store = new SqliteTransferImportStore(target, [new SqliteKnowledgeTransferSection(target)]);
  await new ImportWorkspace(new InspectWorkspaceImport(), store).execute({teamId: "team-2",
    selection: TransferCategorySelection.from(["knowledge"]), reader});
  const attachment = {knowledgeBaseId: "default", noteId: "source", title: "Index", path: ""};
  assert.deepEqual((await new SQLiteKnowledgeBaseStore(target).loadNote("team-2", attachment)).outgoingLinks, ["target"]);
  await assert.rejects(new SQLiteKnowledgeBaseStore(target).loadNote("team-1", attachment), /Wissensnotiz fehlt/);
});
