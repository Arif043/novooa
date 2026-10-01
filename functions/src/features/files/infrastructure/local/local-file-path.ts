import {mkdir, writeFile} from "node:fs/promises";
import path from "node:path";
import {type FileContent} from "../../domain/repositories/team-file-store.js";

export function localFilePath(rootDirectory: string, storagePath: string): string {
  return path.join(rootDirectory, storagePath);
}

export async function writeLocalFile(
  rootDirectory: string,
  storagePath: string,
  content: FileContent,
): Promise<void> {
  const destination = localFilePath(rootDirectory, storagePath);
  await mkdir(path.dirname(destination), {recursive: true});
  await writeFile(destination, content);
}
