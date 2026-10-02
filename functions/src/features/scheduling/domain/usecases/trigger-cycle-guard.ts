import {type FolderAncestry} from "../../../files/domain/repositories/folder-ancestry.js";
import {type TaskDefinition} from "../../../task_execution/domain/entities/task.js";
import {type TaskDefinitionStore} from "../../../task_execution/domain/repositories/task-definition-store.js";
import {fileWriteSitesOf} from "../../../task_execution/domain/services/file-write-sites.js";
import {isFileEventSource} from "./event-trigger-matching.js";
import {type EventTriggerConfig} from "../entities/event-trigger-config.js";
import {type TaskTriggerStore} from "../repositories/task-trigger-store.js";
import {
  describeCycle,
  findTriggerCycles,
  type AnalyzedTask,
  type AnalyzedTrigger,
  type TriggerCycle,
} from "./detect-trigger-cycles.js";

/** `blocked`: nicht zulässig, mit Begründung. `warnings`: mögliche Schleifen, die der Nutzer bewusst bestätigen kann. */
export type CycleVerdict = {blocked: string | null; warnings: string[]};

export type CycleGuardPorts = {
  tasks: Pick<TaskDefinitionStore, "list">;
  triggers: Pick<TaskTriggerStore, "listEnabledEventTriggers">;
  folders: FolderAncestry;
};

/**
 * Prüft vor einer Änderung, ob sie in der Aufgaben-Trigger-Landschaft einen
 * Zyklus schließt. Eine sichere Selbstschleife ist ein Fehler, alles andere
 * eine Warnung — die Laufzeit stoppt jede Schleife ohnehin.
 */
export class TriggerCycleGuard {
  constructor(private readonly ports: CycleGuardPorts) {}

  /** Ein neuer oder wieder aktivierter Event-Trigger. */
  async checkTrigger(
    teamId: string,
    trigger: {id: string; taskId: string; config: EventTriggerConfig},
  ): Promise<CycleVerdict> {
    if (!isFileEventSource(trigger.config.source)) return {blocked: null, warnings: []};
    const model = await this.model(teamId);
    const triggers = [...model.triggers.filter((item) => item.id !== trigger.id), trigger];
    const cycles = findTriggerCycles({...model, triggers});
    return verdictFor(cycles.filter((cycle) => cycle.steps.some((step) => step.triggerId === trigger.id)));
  }

  /** Eine gespeicherte Aufgabe, die ihre Schreibstellen geändert haben kann. */
  async checkTask(teamId: string, definition: TaskDefinition): Promise<CycleVerdict> {
    const model = await this.model(teamId, definition);
    const cycles = findTriggerCycles(model);
    return verdictFor(cycles.filter((cycle) => cycle.steps.some((step) => step.taskId === definition.id)));
  }

  private async model(teamId: string, replacing?: TaskDefinition) {
    const [definitions, triggers, parents] = await Promise.all([
      this.ports.tasks.list(teamId),
      this.ports.triggers.listEnabledEventTriggers(teamId),
      this.ports.folders.parentsOf(teamId),
    ]);
    const tasks: AnalyzedTask[] = [...definitions.filter((item) => item.id !== replacing?.id), ...(replacing ? [replacing] : [])]
      .map((item) => ({id: item.id, title: item.title, sites: fileWriteSitesOf(item)}));
    const analyzed: AnalyzedTrigger[] = triggers
      .filter((trigger) => trigger.type === "event")
      .map((trigger) => ({id: trigger.id, taskId: trigger.taskId, config: trigger.eventConfig}));
    return {tasks, triggers: analyzed, folderChainOf: (folderId: string) => chainIn(parents, folderId)};
  }
}

function verdictFor(cycles: TriggerCycle[]): CycleVerdict {
  const blocking = cycles.find((cycle) => cycle.selfLoop && cycle.certain);
  return {
    blocked: blocking === undefined ? null : selfLoopMessage(blocking),
    warnings: cycles.filter((cycle) => cycle !== blocking).map(warningMessage),
  };
}

function selfLoopMessage(cycle: TriggerCycle): string {
  return `Die Aufgabe „${cycle.steps[0].taskTitle}“ würde sich über diesen Auslöser immer wieder selbst starten, `
    + "weil sie Dateien schreibt, auf die er reagiert. Wähle ein anderes Ziel für den Auslöser "
    + "oder ein anderes Ausgabeverzeichnis für die Aufgabe.";
}

function warningMessage(cycle: TriggerCycle): string {
  const prefix = cycle.selfLoop ? "Mögliche Selbstschleife" : "Mögliche Schleife";
  return `${prefix}: ${describeCycle(cycle)}. Zur Laufzeit wird sie gestoppt, sobald ein Auslöser innerhalb derselben Kette erneut starten würde.`;
}

function chainIn(parents: ReadonlyMap<string, string | null>, folderId: string): string[] {
  const chain: string[] = [];
  for (let current: string | null | undefined = folderId; current && !chain.includes(current); current = parents.get(current)) {
    chain.push(current);
  }
  return chain;
}
