import {type RuntimeDatabase} from "../../../../db/database.js";
import {type ApplicationLogger} from "../../../../shared/logging/application-logger.js";
import {ExportWorkspace} from "../../domain/usecases/export-workspace.js";
import {ImportWorkspace} from "../../domain/usecases/import-workspace.js";
import {InspectWorkspaceImport} from "../../domain/usecases/inspect-workspace-import.js";
import {LocalTransferUploadStore} from "./local-transfer-upload-store.js";
import {LocalWorkspaceTransferHttpHandler} from "./local-workspace-transfer-http-handler.js";
import {SqliteDataTransferSection} from "./sqlite-data-transfer-section.js";
import {SqliteFilesTransferImporter} from "./sqlite-files-transfer-importer.js";
import {SqliteFilesTransferSection} from "./sqlite-files-transfer-section.js";
import {SqliteKnowledgeTransferSection} from "./sqlite-knowledge-transfer-section.js";
import {SqliteTasksTransferSection} from "./sqlite-tasks-transfer-section.js";
import {SqliteTransferImportStore} from "./sqlite-transfer-import-store.js";

export function createLocalWorkspaceTransferHttpHandler(options: {
  database: RuntimeDatabase;
  runtimeRoot: string;
  teamId: string;
  notifier: {publish(topic: string): void};
  logger: ApplicationLogger;
}): LocalWorkspaceTransferHttpHandler {
  const data = new SqliteDataTransferSection(options.database);
  const knowledge = new SqliteKnowledgeTransferSection(options.database);
  const tasks = new SqliteTasksTransferSection(options.database);
  const inspectImport = new InspectWorkspaceImport();
  const importStore = new SqliteTransferImportStore(options.database, [
    new SqliteFilesTransferImporter(options.runtimeRoot), data, knowledge, tasks,
  ]);
  return new LocalWorkspaceTransferHttpHandler({
    exportWorkspace: new ExportWorkspace([
      new SqliteFilesTransferSection(options.database, options.runtimeRoot), data, knowledge, tasks,
    ]),
    inspectImport,
    importWorkspace: new ImportWorkspace(inspectImport, importStore),
    uploads: new LocalTransferUploadStore(options.runtimeRoot),
    teamId: options.teamId,
    notifier: options.notifier,
    logger: options.logger,
  });
}
