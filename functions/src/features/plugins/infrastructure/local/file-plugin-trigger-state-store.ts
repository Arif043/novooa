import {mkdir, readFile, rm, writeFile} from "node:fs/promises";
import path from "node:path";
import {type PluginTriggerStateStore} from "../../domain/repositories/plugin-trigger-state-store.js";

/** Eine JSON-Datei je Trigger (`<ordner>/<trigger-id>.json`). */
export class FilePluginTriggerStateStore implements PluginTriggerStateStore {
  constructor(private readonly location: string) {}

  async read(triggerId: string): Promise<unknown> {
    const text = await readFile(this.fileOf(triggerId), "utf8").catch((error: NodeJS.ErrnoException) => {
      if (error.code === "ENOENT") return null;
      throw error;
    });
    return text === null ? undefined : (JSON.parse(text) as {state?: unknown}).state;
  }

  async write(triggerId: string, state: unknown): Promise<void> {
    await mkdir(this.location, {recursive: true});
    await writeFile(this.fileOf(triggerId), JSON.stringify({state: state ?? null}), {mode: 0o600});
  }

  async delete(triggerId: string): Promise<void> {
    await rm(this.fileOf(triggerId), {force: true});
  }

  private fileOf(triggerId: string): string {
    if (!/^[A-Za-z0-9-]{1,100}$/.test(triggerId)) throw new Error("Ungültige Trigger-ID.");
    return path.join(this.location, `${triggerId}.json`);
  }
}
