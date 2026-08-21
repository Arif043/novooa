import {
  type TeamFileContent,
  type TeamFileContentReader,
} from "../../../../files/domain/repositories/team-file-content-reader.js";
import {type FileReference} from "../../../domain/entities/workflow-value.js";

export async function mediaDataUrlFor(
  media: FileReference,
  teamId: string,
  fileContentReader: TeamFileContentReader,
): Promise<string> {
  const file = await fileContentFor(media, teamId, fileContentReader);
  if (!file.contentType.startsWith("image/")) {
    throw new Error("Die referenzierte Datei ist kein Bild.");
  }
  return `data:${file.contentType};base64,${Buffer.from(file.content).toString("base64")}`;
}

export function fileContentFor(
  file: FileReference,
  teamId: string,
  fileContentReader: TeamFileContentReader,
): Promise<TeamFileContent> {
  return fileContentReader.readTeamFileContent(
    teamId,
    file.fileId,
    file.versionId,
  );
}
