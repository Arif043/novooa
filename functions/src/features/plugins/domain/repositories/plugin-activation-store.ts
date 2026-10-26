/** Welche Plugins ein Arbeitsbereich aktiviert hat. Standard ist aus. */
export interface PluginActivationStore {
  /** Aktivierte Plugins mit Zeitpunkt der Aktivierung. */
  enabledPlugins(teamId: string): Promise<ReadonlyMap<string, string>>;
  isEnabled(teamId: string, pluginId: string): Promise<boolean>;
  enable(teamId: string, pluginId: string, uid: string): Promise<void>;
  disable(teamId: string, pluginId: string): Promise<void>;
}

/** Was Bausteine und Auslöser eines Plugins vor dem Ausführen fragen. */
export type PluginAvailability = Pick<PluginActivationStore, "isEnabled">;
