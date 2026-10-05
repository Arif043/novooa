import {type NodeOutputValue} from "../../../task_execution/domain/entities/workflow-value.js";

export type PluginPrimitiveRun = {
  pluginId: string;
  nodeType: string;
  /** Konfiguration des Bausteins, Template-Ausdrücke sind bereits aufgelöst. */
  settings: Record<string, string | number | boolean>;
};

/** Das Plugin ist installiert, ließ sich aber nicht (erfolgreich) ausführen. */
export class PluginRunError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "PluginRunError";
  }
}

export interface PluginRunner {
  /** Wirft `PluginNotFoundError`, `PluginRunError`. Liefert die im Manifest deklarierten Ausgaben, typisiert. */
  runPrimitive(run: PluginPrimitiveRun): Promise<Record<string, NodeOutputValue>>;
}
