import {type NodeExecutionResult} from "../../../domain/entities/task.js";
import {type NodeResultOrFailure} from "../../../domain/executors/node-executor.js";
import {type RunEffectRecorder} from "../../../domain/services/run-effect-recorder.js";

/**
 * Hängt die Folgen eines Bausteins an sein Ergebnis — vor dem Journal, damit ein übernommenes
 * Ergebnis sie mitbringt und beim Wiederholen nichts doppelt gezählt wird.
 */
export function withEffects(resultOrFailure: NodeResultOrFailure, recorder: RunEffectRecorder): NodeResultOrFailure {
  const effects = recorder.effects;
  if (effects.length === 0) return resultOrFailure;
  return resultOrFailure.map((result) => ({...result, effects: [...effects]}));
}

/**
 * Ein aus dem Journal übernommenes Ergebnis lief nicht neu, sein Recorder ist also leer: Seine
 * Effekte werden übernommen, damit der umschließende Baustein (etwa eine Schleife) vollständig ist.
 */
export function adoptReplayedEffects(result: NodeExecutionResult, recorder: RunEffectRecorder): void {
  if (recorder.effects.length === 0 && result.effects !== undefined) recorder.adopt(result.effects);
}
