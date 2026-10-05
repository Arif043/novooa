import {startEventTriggerRun, type EventTriggerRunPorts} from "../../../scheduling/domain/usecases/start-event-trigger-run.js";
import {PluginNotFoundError} from "../entities/stored-plugin.js";
import {type PluginTriggerRunner} from "../repositories/plugin-runner.js";
import {type PluginTriggerStateStore} from "../repositories/plugin-trigger-state-store.js";

export type PluginTriggerPollFailure = {triggerId: string; pluginId: string; error: unknown};

/** Zeitüberschreitung, kaputter Handler und Ähnliches: ein Trigger darf die anderen nicht aufhalten. */
export type PollPluginTriggersPorts = EventTriggerRunPorts & {
  runner: PluginTriggerRunner;
  states: PluginTriggerStateStore;
  teamId: string;
  onFailure?: (failure: PluginTriggerPollFailure) => void;
};

export const pluginEventSource = "plugin";

/**
 * Fragt alle aktiven Plugin-Trigger nach neuen Ereignissen und startet für jedes die Aufgabe. Der Zustand wird erst
 * gespeichert, nachdem alle Läufe eingereiht sind: Scheitert das Einreihen, kommt dasselbe Ereignis beim nächsten
 * Durchgang erneut (lieber doppelt als verloren).
 */
export async function pollPluginTriggers(ports: PollPluginTriggersPorts): Promise<void> {
  const triggers = await ports.triggerStore.listEnabledEventTriggers(ports.teamId);
  for (const trigger of triggers) {
    const reference = trigger.eventConfig.plugin;
    if (trigger.eventConfig.source !== pluginEventSource || reference === undefined) continue;
    try {
      const result = await ports.runner.pollTrigger({
        pluginId: reference.pluginId,
        triggerType: reference.type,
        settings: reference.settings,
        state: await ports.states.read(trigger.id),
      });
      for (const event of result.events) {
        await startEventTriggerRun(trigger, {
          context: event.context,
          event: {source: pluginEventSource, pluginId: reference.pluginId, type: reference.type, data: event.data},
        }, ports);
      }
      await ports.states.write(trigger.id, result.state);
    } catch (error) {
      // Ein nicht installiertes Plugin ist erwartbar (Import, Deinstallation) und kein Fehler des Systems.
      if (!(error instanceof PluginNotFoundError)) ports.onFailure?.({triggerId: trigger.id, pluginId: reference.pluginId, error});
    }
  }
}
