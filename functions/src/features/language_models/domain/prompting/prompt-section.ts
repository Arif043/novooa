/**
 * Arten von Prompt-Abschnitten in fester Reihenfolge. Die Reihenfolge hier bestimmt die Reihenfolge
 * im Prompt — nicht die Reihenfolge, in der eine Aufrufstelle den Builder bedient.
 */
export const promptSectionKinds = [
  "role", "rules", "employee", "attachments", "reference", "output_format", "response_language",
  "task", "context",
] as const;

export type PromptSectionKind = (typeof promptSectionKinds)[number];

/** Systemteil: wie das Modell arbeitet. Nutzerteil: was es diesmal tun soll und womit. */
export type PromptSectionTarget = "system" | "user";

const userKinds: ReadonlySet<PromptSectionKind> = new Set(["task", "context"]);

/** Abschnitte, die mehrfach vorkommen dürfen; alle anderen ersetzt ein erneuter Aufruf. */
export const repeatableKinds: ReadonlySet<PromptSectionKind> = new Set(["reference", "context"]);

export type PromptSection = {
  readonly kind: PromptSectionKind;
  /** Unterscheidet mehrere Abschnitte gleicher Art, z. B. `context name="rechnung"`. */
  readonly name?: string;
  readonly content: string;
};

export function promptSectionTarget(kind: PromptSectionKind): PromptSectionTarget {
  return userKinds.has(kind) ? "user" : "system";
}

/** Sortiert nach Art; innerhalb einer Art bleibt die Einfügereihenfolge (stabile Sortierung). */
export function comparePromptSections(left: PromptSection, right: PromptSection): number {
  return promptSectionKinds.indexOf(left.kind) - promptSectionKinds.indexOf(right.kind);
}
