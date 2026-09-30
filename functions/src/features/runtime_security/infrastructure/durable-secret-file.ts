import {randomUUID} from "node:crypto";
import {mkdir, open, rename, rm, stat} from "node:fs/promises";
import {dirname} from "node:path";

export async function writeDurableSecretFile(path: string, value: string): Promise<void> {
  await mkdir(dirname(path), {recursive: true, mode: 0o700});
  const temporary = `${path}.${randomUUID()}.new`;
  try {
    await writeSyncedFile(temporary, value, path);
    await rename(temporary, path);
    await syncSecretDirectory(dirname(path));
  } finally {
    await rm(temporary, {force: true});
  }
}

async function writeSyncedFile(path: string, value: string, destination: string): Promise<void> {
  const file = await open(path, "wx", 0o600);
  try {
    await preserveOwner(destination, file);
    await file.writeFile(value, "utf8");
    await file.sync();
  } finally {
    await file.close();
  }
}

async function preserveOwner(path: string, file: Awaited<ReturnType<typeof open>>): Promise<void> {
  if (process.platform === "win32") return;
  try {
    const owner = await stat(path);
    const temporary = await file.stat();
    if (owner.uid !== temporary.uid || owner.gid !== temporary.gid) await file.chown(owner.uid, owner.gid);
  } catch (error) {
    if (!(error instanceof Error && "code" in error && error.code === "ENOENT")) throw error;
  }
}

export async function syncSecretDirectory(path: string): Promise<void> {
  if (process.platform === "win32") return;
  const directory = await open(path, "r");
  try {
    await directory.sync();
  } finally {
    await directory.close();
  }
}
