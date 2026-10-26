/** Ob ein eingebautes Plugin im Arbeitsbereich aktiv ist; `enabledAt` nur, wenn ja. */
export type PluginState = {id: string; enabled: boolean; enabledAt: string | null};

/** Fachlicher Fehler beim Schalten eines Plugins. */
export class PluginError extends Error {
  constructor(readonly code: "plugin_not_found", message: string) {
    super(message);
  }
}
