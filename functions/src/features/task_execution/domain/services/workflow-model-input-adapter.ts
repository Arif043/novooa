import {type ModelInputValue} from
  "../../../machine_learning/domain/entities/model-input-source.js";
import {type TeamFileContentReader} from
  "../../../files/domain/repositories/team-file-content-reader.js";
import {type NodeOutputValue} from "../entities/task.js";

export async function modelInputForWorkflowValue(
  value: NodeOutputValue,
  teamId: string,
  fileContentReader: TeamFileContentReader,
): Promise<ModelInputValue> {
  switch (value.type) {
    case "string":
      return {type: "text", value: value.value};
    case "datetime":
      return {type: "datetime", value: value.value};
    case "number":
      return {type: "number", value: value.value};
    case "boolean":
      return {type: "boolean", value: value.value};
    case "json":
      return {type: "json", value: value.value};
    case "file":
    case "media":
      return modelInputForFile(value.value, teamId, fileContentReader);
  }
}

async function modelInputForFile(
  file: Extract<NodeOutputValue, {type: "file" | "media"}>["value"],
  teamId: string,
  fileContentReader: TeamFileContentReader,
): Promise<ModelInputValue> {
  const content = await fileContentReader.readTeamFileContent(
    teamId,
    file.fileId,
    file.versionId,
  );
  if (content.contentType.startsWith("image/")) {
    return {type: "image", contentType: content.contentType, bytes: content.content};
  }
  return {type: "file", contentType: content.contentType, bytes: content.content};
}
