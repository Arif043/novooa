import {type NestedRun} from "../../../domain/entities/nested-run.js";
import {type RunEffect} from "../../../domain/entities/run-effect.js";
import {type NodeExecutionResult} from "../../../domain/entities/task.js";
import {type NodeResultOrFailure} from "../../../domain/executors/node-executor.js";
import {type RunEffectRecorder} from "../../../domain/services/run-effect-recorder.js";
import {type NestedRunCollector} from "./nested-run-collector.js";

/** Was ein Baustein über sein Ergebnis hinaus hinterlässt: Folgen und innere Läufe. */
export type NodeRunTrace = {effects: RunEffectRecorder; nested: NestedRunCollector};

/** Die Spur als Felder eines Ergebnisses oder gescheiterten Bausteins; leere Teile fallen weg. */
export function traceFields(trace: NodeRunTrace | undefined): {effects?: RunEffect[]; nested?: NestedRun[]} {
  if (trace === undefined) return {};
  const effects = trace.effects.effects;
  const nested = trace.nested.runs;
  return {
    ...(effects.length > 0 ? {effects: [...effects]} : {}),
    ...(nested.length > 0 ? {nested: [...nested]} : {}),
  };
}

/**
 * Hängt die Spur an das Ergebnis — vor dem Journal, damit ein übernommenes Ergebnis sie
 * mitbringt und beim Wiederholen nichts doppelt gezählt wird.
 */
export function withTrace(resultOrFailure: NodeResultOrFailure, trace: NodeRunTrace): NodeResultOrFailure {
  const fields = traceFields(trace);
  if (fields.effects === undefined && fields.nested === undefined) return resultOrFailure;
  return resultOrFailure.map((result) => ({...result, ...fields}));
}

/**
 * Ein aus dem Journal übernommenes Ergebnis lief nicht neu, sein Recorder ist also leer: Seine
 * Effekte werden übernommen, damit der umschließende Baustein (etwa eine Schleife) vollständig ist.
 */
export function adoptReplayedEffects(result: NodeExecutionResult, recorder: RunEffectRecorder): void {
  if (recorder.effects.length === 0 && result.effects !== undefined) recorder.adopt(result.effects);
}
