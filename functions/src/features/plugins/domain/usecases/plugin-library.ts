import {type StoredPlugin} from "../entities/stored-plugin.js";
import {type PluginSettingsStore} from "../repositories/plugin-settings-store.js";
import {type PluginStore} from "../repositories/plugin-store.js";

export class ListPlugins {
  constructor(private readonly store: PluginStore) {}

  execute(): Promise<StoredPlugin[]> {
    return this.store.list();
  }
}

export class UninstallPlugin {
  constructor(private readonly store: PluginStore, private readonly settings: PluginSettingsStore) {}

  async execute(id: string): Promise<void> {
    await this.store.delete(id);
    await this.settings.delete(id);
  }
}
