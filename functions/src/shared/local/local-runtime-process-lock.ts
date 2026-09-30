import {mkdir} from "node:fs/promises";
import {lock} from "proper-lockfile";
import {join} from "node:path";

export async function acquireLocalRuntimeProcessLock(runtimeRoot: string): Promise<() => Promise<void>> {
  await mkdir(runtimeRoot, {recursive: true, mode: 0o700});
  try {
    return await lock(runtimeRoot, {
      lockfilePath: join(runtimeRoot, ".runtime-process.lock"), stale: 30000, update: 10000, retries: 0,
    });
  } catch (error) {
    if (error instanceof Error && "code" in error && error.code === "ELOCKED") {
      throw new Error("Runtime-Daten werden verwendet. Runtime vor der Rotation stoppen; nach einem Absturz 30 Sekunden warten.");
    }
    throw error;
  }
}
