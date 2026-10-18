import {isValidScriptWorkflowOutputName, scriptWorkflowOutputTypes} from "./script-workflow-outputs.js";

export type ScriptDraft = {
  script: string;
  workflowOutputs: ReadonlyArray<{name: string; typ: string}>;
};

/**
 * Prüft einen vom KI-Agenten vorgeschlagenen Script-Entwurf statisch, ohne ihn
 * auszuführen. Die Meldungen gehen zurück an den Orchestrator.
 */
export function scriptDraftProblems(draft: ScriptDraft): string[] {
  if (draft.script.trim().length === 0) return ["Das Script ist leer."];
  return [...nameProblems(draft), ...typeProblems(draft), ...declarationProblems(draft), ...templateProblems(draft)];
}

/** `{{…}}` im Code wird nicht ersetzt; gemeint ist fast immer `workflow_input`. */
function templateProblems(draft: ScriptDraft): string[] {
  return /\{\{\s*[\p{L}_][\p{L}\p{N}_.]*\s*\}\}/u.test(draft.script)
    ? ["Das Script enthält {{…}}; Werte liest ein Script nur mit workflow_input(\"name\")."]
    : [];
}

function nameProblems(draft: ScriptDraft): string[] {
  const names = draft.workflowOutputs.map((output) => output.name);
  const invalid = names.filter((name) => !isValidName(name))
    .map((name) => `Der Ausgabename „${name}“ ist ungültig (Python-Bezeichner, nicht „value“).`);
  const duplicates = names.filter((name, index) => names.indexOf(name) !== index)
    .map((name) => `Der Ausgabename „${name}“ ist doppelt vergeben.`);
  return [...invalid, ...duplicates];
}

/** Ohne Type Guard, damit `name` nach der Negation nicht zu `never` wird. */
function isValidName(name: string): boolean {
  return isValidScriptWorkflowOutputName(name);
}

function typeProblems(draft: ScriptDraft): string[] {
  const allowed: readonly string[] = scriptWorkflowOutputTypes;
  return draft.workflowOutputs.filter((output) => !allowed.includes(output.typ))
    .map((output) => `Der Typ „${output.typ}“ von „${output.name}“ ist unbekannt.`);
}

function declarationProblems(draft: ScriptDraft): string[] {
  return draft.workflowOutputs
    .filter((output) => !draft.script.includes(`workflow_output("${output.name}"`) &&
      !draft.script.includes(`workflow_output('${output.name}'`))
    .map((output) => `„${output.name}“ ist angekündigt, wird im Script aber nicht per workflow_output gesetzt.`);
}
