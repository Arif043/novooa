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

/** Ein Ereignis, das ein Plugin-Trigger gemeldet hat. */
export type PluginTriggerEvent = {
  /** Lesbarer Auslösetext der Aufgabe. */
  context: string;
  /** Strukturierte Daten; in Aufgaben als `{{ereignis.feld}}` erreichbar. */
  data: Record<string, unknown>;
};

export type PluginTriggerPoll = {
  pluginId: string;
  triggerType: string;
  settings: Record<string, string | number | boolean>;
  /** Was der Trigger beim letzten Mal zurückgegeben hat (z. B. ein Cursor). */
  state: unknown;
};

export type PluginTriggerPollResult = {events: PluginTriggerEvent[]; state: unknown};

export interface PluginTriggerRunner {
  /** Fragt einen Trigger des Plugins nach neuen Ereignissen. Wirft `PluginNotFoundError`, `PluginRunError`. */
  pollTrigger(poll: PluginTriggerPoll): Promise<PluginTriggerPollResult>;
}

export interface PluginRunner {

  /** Wirft `PluginNotFoundError`, `PluginRunError`. Liefert die im Manifest deklarierten Ausgaben, typisiert. */
  runPrimitive(run: PluginPrimitiveRun): Promise<Record<string, NodeOutputValue>>;
}
