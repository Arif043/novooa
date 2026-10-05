import {type PluginField} from "../entities/plugin-manifest.js";
import {PluginPackageError} from "../entities/plugin-package-error.js";
import {PluginNotFoundError} from "../entities/stored-plugin.js";
import {type PluginSettingsStore, type PluginSettingValues} from "../repositories/plugin-settings-store.js";
import {type PluginStore} from "../repositories/plugin-store.js";

export type PluginSettingsView = {
  /** Werte ohne Geheimnisse. */
  values: Record<string, string | number | boolean>;
  /** Schlüssel der Geheimnisse, die gesetzt sind — ihre Werte verlassen das Backend nie. */
  secretsSet: string[];
};

async function panelFields(store: PluginStore, pluginId: string): Promise<PluginField[]> {
  const plugin = await store.find(pluginId);
  if (plugin === undefined) throw new PluginNotFoundError(pluginId);
  return plugin.manifest.settingsPanels.flatMap((panel) => panel.fields);
}

export class GetPluginSettings {
  constructor(private readonly store: PluginStore, private readonly settings: PluginSettingsStore) {}

  async execute(pluginId: string): Promise<PluginSettingsView> {
    const fields = await panelFields(this.store, pluginId);
    const stored = await this.settings.read(pluginId);
    const secrets = new Set(fields.filter((field) => field.secret).map((field) => field.key));
    const values: PluginSettingsView["values"] = {};
    for (const field of fields) {
      if (!secrets.has(field.key) && stored[field.key] !== undefined) values[field.key] = stored[field.key]!;
      else if (!secrets.has(field.key) && field.defaultValue !== undefined) values[field.key] = field.defaultValue;
    }
    return {values, secretsSet: [...secrets].filter((key) => stored[key] !== undefined && stored[key] !== "")};
  }
}

/** Übernimmt Werte für bekannte Felder; ein leeres Geheimnis lässt den gespeicherten Wert unverändert. */
export class SetPluginSettings {
  constructor(private readonly store: PluginStore, private readonly settings: PluginSettingsStore) {}

  async execute(pluginId: string, input: PluginSettingValues): Promise<void> {
    const fields = await panelFields(this.store, pluginId);
    const known = new Map(fields.map((field) => [field.key, field]));
    const current = await this.settings.read(pluginId);
    const next: PluginSettingValues = {...current};
    for (const [key, value] of Object.entries(input)) {
      const field = known.get(key);
      if (field === undefined) throw new PluginPackageError(`Die Einstellung „${key}“ gehört nicht zu diesem Plugin.`);
      if (field.secret && value === "") continue;
      next[key] = checked(field, value);
    }
    for (const field of fields) {
      if (field.required && (next[field.key] === undefined || next[field.key] === "")) {
        throw new PluginPackageError(`„${field.label}“ ist erforderlich.`);
      }
    }
    await this.settings.write(pluginId, next);
  }
}

function checked(field: PluginField, value: string | number | boolean): string | number | boolean {
  const valid = field.kind === "number" ? typeof value === "number" && Number.isFinite(value)
    : field.kind === "toggle" ? typeof value === "boolean"
      : typeof value === "string" && value.length <= 5000 &&
        (field.kind !== "choice" || value === "" || (field.options ?? []).some((option) => option.value === value));
  if (!valid) throw new PluginPackageError(`Der Wert für „${field.label}“ ist ungültig.`);
  return value;
}
