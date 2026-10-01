import {parseFileVersionLimit} from "../../domain/entities/file-version-rotation.js";

export function fileVersionLimitFromEnvironment(): number {
  return parseFileVersionLimit(process.env.LOCAL_RUNTIME_FILE_VERSION_LIMIT);
}
