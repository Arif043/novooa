import {type NodeOutputValue} from "../task_execution/domain/entities/task.js";
import {type RunEffectRecorder} from "../task_execution/domain/services/run-effect-recorder.js";

type ActionWithEffect = {
  id: string;
  effectLabel?(outputs: Record<string, NodeOutputValue>): string | undefined;
};

/** Meldet die Folge einer ändernden Plugin-Aktion; lesende Aktionen haben kein `effectLabel`. */
export function recordExternalAction(
  effects: RunEffectRecorder,
  plugin: string,
  action: ActionWithEffect,
  outputs: Record<string, NodeOutputValue>,
): void {
  const label = action.effectLabel?.(outputs);
  if (label !== undefined) effects.record({kind: "externalAction", plugin, action: action.id, label});
}

/** Ein Textfeld aus einem JSON-Wert der Ausgaben, z. B. `value.orderNumber`. */
export function jsonField(output: NodeOutputValue | undefined, field: string): string | undefined {
  if (output?.type !== "json" || typeof output.value !== "object" || output.value === null) return undefined;
  const value = (output.value as Record<string, unknown>)[field];
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

export function changed(outputs: Record<string, NodeOutputValue>): boolean {
  const flag = outputs.changed;
  return flag?.type !== "boolean" || flag.value;
}
