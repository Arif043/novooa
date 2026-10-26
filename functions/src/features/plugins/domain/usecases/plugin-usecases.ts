import {PluginError, type PluginState} from "../entities/plugin-state.js";
import {type PluginActivationStore} from "../repositories/plugin-activation-store.js";

/** Alle eingebauten Plugins in der Reihenfolge des Katalogs, je mit ihrem Zustand im Arbeitsbereich. */
export class ListPlugins {
  constructor(private readonly catalog: readonly string[], private readonly store: PluginActivationStore) {}

  async execute(teamId: string): Promise<PluginState[]> {
    const enabled = await this.store.enabledPlugins(teamId);
    return this.catalog.map((id) => ({id, enabled: enabled.has(id), enabledAt: enabled.get(id) ?? null}));
  }
}

/** Ein Admin schaltet ein Plugin an oder aus; nur Plugins des Katalogs. */
export class SetPluginEnabled {
  constructor(private readonly catalog: readonly string[], private readonly store: PluginActivationStore) {}

  async execute(input: {teamId: string; pluginId: string; enabled: boolean; uid: string}): Promise<PluginState> {
    if (!this.catalog.includes(input.pluginId)) {
      throw new PluginError("plugin_not_found", "Dieses Plugin gibt es nicht.");
    }
    if (input.enabled) await this.store.enable(input.teamId, input.pluginId, input.uid);
    else await this.store.disable(input.teamId, input.pluginId);
    const enabledAt = (await this.store.enabledPlugins(input.teamId)).get(input.pluginId) ?? null;
    return {id: input.pluginId, enabled: enabledAt !== null, enabledAt};
  }
}
