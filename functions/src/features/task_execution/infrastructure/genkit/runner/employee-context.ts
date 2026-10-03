import type {SkillAttachment, WorkflowNode} from "./task-definition.js";

/** Mitarbeiter, der einem Baustein zugewiesen wurde (nur die ID), oder undefined. */
export function employeeIdFor(node: WorkflowNode): string | undefined {
  if (node.config.primitive === "prompt") return node.config.employeeId;
  if (node.config.primitive === "iterativeRefinement") return node.config.employeeId;
  return undefined;
}

/** Fähigkeiten, die der Nutzer dem Baustein selbst zugewiesen hat (nicht die eines Mitarbeiters). */
export function ownSkillAttachmentsFor(node: WorkflowNode): SkillAttachment[] {
  if (node.config.primitive === "prompt") return node.config.skillAttachments;
  if (node.config.primitive === "iterativeRefinement") return node.config.skillAttachments;
  return [];
}

/**
 * Ein Baustein hat entweder einen Mitarbeiter (dessen Fähigkeiten er dann implizit erhält) oder selbst gewählte
 * Fähigkeiten — nie beides. Die Oberfläche räumt beim Umschalten auf; diese Prüfung fängt Altdaten und Aufgaben
 * ab, die auf anderem Weg entstanden sind.
 */
export function assertExclusiveDelegation(node: WorkflowNode): void {
  if (employeeIdFor(node) !== undefined && ownSkillAttachmentsFor(node).length > 0) {
    throw new Error("Ein Baustein kann nicht zugleich einen Mitarbeiter und Fähigkeiten haben. Entferne eines von beiden.");
  }
}
