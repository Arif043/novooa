export type PluginSettingValues = Record<string, string | number | boolean>;

/** Werte der Einstellungs-Panels eines Plugins; überleben Updates, verschwinden mit der Deinstallation. */
export interface PluginSettingsStore {
  read(pluginId: string): Promise<PluginSettingValues>;
  write(pluginId: string, values: PluginSettingValues): Promise<void>;
  delete(pluginId: string): Promise<void>;
}
