import {type RuntimeDatabase} from "../../../../db/database.js";
import {createDirectorySkillStore} from "../../../skills/infrastructure/local/skills-composition.js";
import {ExportWorkspace} from "../../domain/usecases/export-workspace.js";
import {ImportWorkspace} from "../../domain/usecases/import-workspace.js";
import {InspectWorkspaceImport} from "../../domain/usecases/inspect-workspace-import.js";
import {LocalTransferUploadStore} from "./local-transfer-upload-store.js";
import {type WorkspaceTransferRoutesOptions} from "./local-workspace-transfer-routes.js";
import {SQLiteDataTransferSection} from "./sqlite-data-transfer-section.js";
import {SQLiteFilesTransferImporter} from "./sqlite-files-transfer-importer.js";
import {SQLiteFilesTransferSection} from "./sqlite-files-transfer-section.js";
import {SQLiteKnowledgeTransferSection} from "./sqlite-knowledge-transfer-section.js";
import {SQLiteEmployeesTransferSection} from "./sqlite-employees-transfer-section.js";
import {SkillsTransferSection} from "./skills-transfer-section.js";
import {SQLiteTasksTransferSection} from "./sqlite-tasks-transfer-section.js";
import {SQLiteTransferImportStore} from "./sqlite-transfer-import-store.js";

/** Baut die stabilen Abhängigkeiten des Import/Export-Plugins einmal beim Start. */
export function workspaceTransferRoutesOptions(options: {
  database: RuntimeDatabase;
  runtimeRoot: string;
  notifier: {publish(topic: string): void};
}): WorkspaceTransferRoutesOptions {
  const data = new SQLiteDataTransferSection(options.database);
  const knowledge = new SQLiteKnowledgeTransferSection(options.database);
  const employees = new SQLiteEmployeesTransferSection(options.database);
  const skills = new SkillsTransferSection(createDirectorySkillStore(options.runtimeRoot));
  const tasks = new SQLiteTasksTransferSection(options.database);
  const inspectImport = new InspectWorkspaceImport();
  const importStore = new SQLiteTransferImportStore(options.database, [
    new SQLiteFilesTransferImporter(options.runtimeRoot), data, knowledge, skills, employees, tasks,
  ]);
  return {
    exportWorkspace: new ExportWorkspace([
      new SQLiteFilesTransferSection(options.database, options.runtimeRoot), data, knowledge, skills, employees, tasks,
    ]),
    inspectImport,
    importWorkspace: new ImportWorkspace(inspectImport, importStore),
    uploads: new LocalTransferUploadStore(options.runtimeRoot),
    notifier: options.notifier,
  };
}
