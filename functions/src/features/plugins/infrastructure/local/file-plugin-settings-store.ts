import {mkdir, readFile, rm, writeFile} from "node:fs/promises";
import path from "node:path";
import {type PluginSettingsStore, type PluginSettingValues} from "../../domain/repositories/plugin-settings-store.js";

/** Eine JSON-Datei je Plugin (`<ordner>/<plugin-id>.json`), nur für den Runtime-Nutzer lesbar, da sie Geheimnisse enthalten kann. */
export class FilePluginSettingsStore implements PluginSettingsStore {
  constructor(private readonly location: string) {}

  async read(pluginId: string): Promise<PluginSettingValues> {
    const text = await readFile(this.fileOf(pluginId), "utf8").catch((error: NodeJS.ErrnoException) => {
      if (error.code === "ENOENT") return null;
      throw error;
    });
    if (text === null) return {};
    const parsed: unknown = JSON.parse(text);
    return parsed !== null && typeof parsed === "object" && !Array.isArray(parsed) ? parsed as PluginSettingValues : {};
  }

  async write(pluginId: string, values: PluginSettingValues): Promise<void> {
    await mkdir(this.location, {recursive: true});
    await writeFile(this.fileOf(pluginId), JSON.stringify(values), {mode: 0o600});
  }

  async delete(pluginId: string): Promise<void> {
    await rm(this.fileOf(pluginId), {force: true});
  }

  private fileOf(pluginId: string): string {
    if (!/^[a-z][a-z0-9-]{1,39}$/.test(pluginId)) throw new Error("Ungültige Plugin-ID.");
    return path.join(this.location, `${pluginId}.json`);
  }
}
