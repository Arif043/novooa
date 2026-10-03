import {type RuntimeDatabase} from "../../../../db/database.js";
import {createDirectorySkillStore} from "../../../skills/infrastructure/local/skills-composition.js";
import {ExportWorkspace} from "../../domain/usecases/export-workspace.js";
import {ImportWorkspace} from "../../domain/usecases/import-workspace.js";
import {InspectWorkspaceImport} from "../../domain/usecases/inspect-workspace-import.js";
import {LocalTransferUploadStore} from "./local-transfer-upload-store.js";
import {type WorkspaceTransferRoutesOptions} from "./local-workspace-transfer-routes.js";
import {SqliteDataTransferSection} from "./sqlite-data-transfer-section.js";
import {SqliteFilesTransferImporter} from "./sqlite-files-transfer-importer.js";
import {SqliteFilesTransferSection} from "./sqlite-files-transfer-section.js";
import {SqliteKnowledgeTransferSection} from "./sqlite-knowledge-transfer-section.js";
import {SqliteEmployeesTransferSection} from "./employees-transfer-section.js";
import {SkillsTransferSection} from "./skills-transfer-section.js";
import {SqliteTasksTransferSection} from "./sqlite-tasks-transfer-section.js";
import {SqliteTransferImportStore} from "./sqlite-transfer-import-store.js";

/** Baut die stabilen Abhängigkeiten des Import/Export-Plugins einmal beim Start. */
export function workspaceTransferRoutesOptions(options: {
  database: RuntimeDatabase;
  runtimeRoot: string;
  notifier: {publish(topic: string): void};
}): WorkspaceTransferRoutesOptions {
  const data = new SqliteDataTransferSection(options.database);
  const knowledge = new SqliteKnowledgeTransferSection(options.database);
  const employees = new SqliteEmployeesTransferSection(options.database);
  const skills = new SkillsTransferSection(createDirectorySkillStore(options.runtimeRoot));
  const tasks = new SqliteTasksTransferSection(options.database);
  const inspectImport = new InspectWorkspaceImport();
  const importStore = new SqliteTransferImportStore(options.database, [
    new SqliteFilesTransferImporter(options.runtimeRoot), data, knowledge, skills, employees, tasks,
  ]);
  return {
    exportWorkspace: new ExportWorkspace([
      new SqliteFilesTransferSection(options.database, options.runtimeRoot), data, knowledge, skills, employees, tasks,
    ]),
    inspectImport,
    importWorkspace: new ImportWorkspace(inspectImport, importStore),
    uploads: new LocalTransferUploadStore(options.runtimeRoot),
    notifier: options.notifier,
  };
}
