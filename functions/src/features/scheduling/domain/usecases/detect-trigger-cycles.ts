import {type EventTriggerConfig} from "../entities/event-trigger-config.js";
import {type FileWriteSite} from "../entities/file-write-site.js";
import {writeMatch, type WriteMatch} from "./trigger-write-matching.js";

export type AnalyzedTask = {id: string; title: string; sites: readonly FileWriteSite[]};
export type AnalyzedTrigger = {id: string; taskId: string; config: EventTriggerConfig};

export type TriggerCycleModel = {
  tasks: readonly AnalyzedTask[];
  /** Nur aktive Event-Trigger; andere Quellen erzeugen keine Kanten. */
  triggers: readonly AnalyzedTrigger[];
  folderChainOf: (folderId: string) => readonly string[];
};

/** Aufgabe `taskId` schreibt etwas, das `triggerId` auslöst; der Trigger startet die nächste Aufgabe des Zyklus. */
export type CycleStep = {taskId: string; taskTitle: string; triggerId: string};

export type TriggerCycle = {
  steps: readonly CycleStep[];
  /** Jede Kante ist sicher, nicht nur möglich. */
  certain: boolean;
  /** Eine Aufgabe startet sich über ihren eigenen Trigger selbst. */
  selfLoop: boolean;
};

type Edge = {triggerId: string; match: WriteMatch};

/**
 * Findet Zyklen im Aufgabengraphen. Analog zum Betriebsmittelbelegungsgraphen
 * (Aufgabe → Trigger = Anforderung, Trigger → Aufgabe = Zuteilung) wird er
 * auf einen Graphen über Aufgaben reduziert, `E = W ⊗ T` (Boolesches
 * Matrixprodukt). Ein Zyklus liegt genau dort vor, wo die transitive Hülle
 * `E⁺` auf der Diagonale eine 1 hat.
 */
export function findTriggerCycles(model: TriggerCycleModel): TriggerCycle[] {
  const edges = edgeMatrix(model);
  const closure = transitiveClosure(edges.map((row) => row.map((edge) => edge !== null)));
  const cycles = new Map<string, TriggerCycle>();
  for (let start = 0; start < model.tasks.length; start++) {
    if (!closure[start][start]) continue;
    const cycle = shortestCycleFrom(start, edges, model.tasks);
    const key = [...new Set(cycle.steps.map((step) => step.taskId))].sort().join("|");
    if (!cycles.has(key)) cycles.set(key, cycle);
  }
  return [...cycles.values()];
}

export function describeCycle(cycle: TriggerCycle): string {
  const titles = cycle.steps.map((step) => `„${step.taskTitle}“`);
  return [...titles, titles[0]].join(" → ");
}

/** `E[a][b]`: Aufgabe `a` kann über einen Trigger Aufgabe `b` starten (bevorzugt die sichere Kante). */
function edgeMatrix(model: TriggerCycleModel): Array<Array<Edge | null>> {
  const index = new Map(model.tasks.map((task, position) => [task.id, position]));
  const edges = model.tasks.map(() => model.tasks.map((): Edge | null => null));
  for (const [from, task] of model.tasks.entries()) {
    for (const trigger of model.triggers) {
      const to = index.get(trigger.taskId);
      if (to === undefined) continue;
      const match = bestMatch(trigger, task, model);
      if (match === null) continue;
      const known = edges[from][to];
      if (known === null || (known.match === "possible" && match === "certain")) {
        edges[from][to] = {triggerId: trigger.id, match};
      }
    }
  }
  return edges;
}

function bestMatch(trigger: AnalyzedTrigger, task: AnalyzedTask, model: TriggerCycleModel): WriteMatch | null {
  const matches = task.sites.map((site) => writeMatch(trigger.config, site, model.folderChainOf));
  if (matches.includes("certain")) return "certain";
  return matches.includes("possible") ? "possible" : null;
}

/** Warshall: Erreichbarkeit über beliebig viele Schritte. */
function transitiveClosure(adjacency: boolean[][]): boolean[][] {
  const closure = adjacency.map((row) => [...row]);
  const size = closure.length;
  for (let via = 0; via < size; via++) {
    for (let from = 0; from < size; from++) {
      if (!closure[from][via]) continue;
      for (let to = 0; to < size; to++) closure[from][to] ||= closure[via][to];
    }
  }
  return closure;
}

/** Kürzester Rundweg über Breitensuche, damit die Meldung nur den Kern des Zyklus nennt. */
function shortestCycleFrom(
  start: number,
  edges: Array<Array<Edge | null>>,
  tasks: readonly AnalyzedTask[],
): TriggerCycle {
  const previous = new Map<number, number>();
  const queue = [start];
  let closing = -1;
  while (closing === -1 && queue.length > 0) {
    const current = queue.shift() as number;
    for (let next = 0; next < tasks.length; next++) {
      if (edges[current][next] === null) continue;
      if (next === start) {
        closing = current;
        break;
      }
      if (!previous.has(next)) {
        previous.set(next, current);
        queue.push(next);
      }
    }
  }
  return cycleThrough(pathTo(closing, start, previous), edges, tasks);
}

function pathTo(last: number, start: number, previous: Map<number, number>): number[] {
  const path = [last];
  while (path[0] !== start) path.unshift(previous.get(path[0]) as number);
  return path;
}

function cycleThrough(
  path: number[],
  edges: Array<Array<Edge | null>>,
  tasks: readonly AnalyzedTask[],
): TriggerCycle {
  const steps = path.map((from, position) => {
    const edge = edges[from][path[(position + 1) % path.length]] as Edge;
    return {step: {taskId: tasks[from].id, taskTitle: tasks[from].title, triggerId: edge.triggerId}, edge};
  });
  return {
    steps: steps.map((entry) => entry.step),
    certain: steps.every((entry) => entry.edge.match === "certain"),
    selfLoop: path.length === 1,
  };
}
