import {readFile, stat} from "node:fs/promises";
import path from "node:path";
import {outputFileContentTypes, type TeamworkOutputField} from "../../../../domain/entities/teamwork-config.js";
import {type NodeOutputValue} from "../../../../domain/entities/workflow-value.js";
import {fileOutputFor} from "../../../../domain/services/file-output-values.js";
import {type TeamFileStore} from "../../../../../files/domain/repositories/team-file-store.js";
import {ModelOutputSchemaError} from "../../../../../language_models/infrastructure/errors/language-model-errors.js";

/** Größer wird eine Ergebnisdatei aus Text nicht; alles darüber ist eher ein Fehler des Modells. */
export const maximumResultFileBytes = 5 * 1024 * 1024;

type FileField = Extract<TeamworkOutputField, {type: "file"}>;

export type ResultFileTarget = {teamId: string; sharedDirectory: string; teamFileStore: TeamFileStore};

/** Legt die Ergebnisdatei eines Datei-Felds als neue Team-Datei ab und liefert den Dateiwert. */
export async function persistedResultFile(
  field: FileField, reportedPath: unknown, target: ResultFileTarget,
): Promise<NodeOutputValue> {
  const name = field.name.trim();
  const absolutePath = resultFilePath(name, reportedPath, target.sharedDirectory);
  const content = await resultFileContent(name, absolutePath);
  const file = await target.teamFileStore.writeTeamFile({
    teamId: target.teamId, content, fileName: path.basename(absolutePath),
    contentType: outputFileContentTypes[field.fileFormat], folderId: null, targetFileId: null,
  });
  return fileOutputFor(file);
}

/** Nur Dateien in `shared/`: Anhänge, Notizen und Fähigkeiten sind keine Ergebnisse. */
export function resultFilePath(name: string, reportedPath: unknown, sharedDirectory: string): string {
  const relative = typeof reportedPath === "string" ? reportedPath.trim() : "";
  const root = path.dirname(sharedDirectory);
  const absolutePath = path.resolve(root, relative);
  if (relative.length === 0 || !absolutePath.startsWith(sharedDirectory + path.sep)) {
    throw new ModelOutputSchemaError(
      `Für das Feld „${name}“ fehlt eine Ergebnisdatei unter ${path.basename(sharedDirectory)}/ (erhalten: „${relative}“).`,
    );
  }
  return absolutePath;
}

async function resultFileContent(name: string, absolutePath: string): Promise<string> {
  const size = await stat(absolutePath).then((info) => (info.isFile() ? info.size : -1), () => -1);
  if (size < 0) throw new ModelOutputSchemaError(`Die Ergebnisdatei für „${name}“ wurde nicht geschrieben.`);
  if (size > maximumResultFileBytes) {
    throw new ModelOutputSchemaError(`Die Ergebnisdatei für „${name}“ ist größer als 5 MB.`);
  }
  return readFile(absolutePath, "utf8");
}
