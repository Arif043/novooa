import type {
  EmployeeAttachment,
  SkillAttachment,
  WorkflowNode,
} from "./task-definition.js";

/** Mitarbeiter, der einem Baustein zugewiesen wurde, oder undefined. */
export function employeeFor(
  node: WorkflowNode,
): EmployeeAttachment | undefined {
  if (node.config.primitive === "prompt") return node.config.employee;
  if (node.config.primitive === "iterativeRefinement") return node.config.employee;
  return undefined;
}

/**
 * Mergt die Skills, die einem Baustein zur Verfügung stehen sollen: node-
 * spezifisch attachte Skills + Default-Skills des zugewiesenen Mitarbeiters.
 * Duplikate (gleiche `skillId`) werden entfernt; node-spezifische Skills
 * gewinnen.
 */
export function mergeNodeAndEmployeeSkills(
  nodeSkills: SkillAttachment[],
  employee?: EmployeeAttachment,
): SkillAttachment[] {
  if (!employee || employee.defaultSkills.length === 0) return nodeSkills;
  const seen = new Set(nodeSkills.map((skill) => skill.skillId));
  const merged: SkillAttachment[] = [...nodeSkills];
  for (const skill of employee.defaultSkills) {
    if (seen.has(skill.skillId)) continue;
    seen.add(skill.skillId);
    merged.push(skill);
  }
  return merged;
}

/**
 * Baut aus einer Prompt-Vorlage und der node-spezifischen Anweisung den
 * User-Prompt. Enthält die Vorlage `{{instruction}}`, wird nur ersetzt;
 * sonst wird die Anweisung an die Vorlage angehängt.
 */
export function renderEmployeePrompt(
  template: string,
  instruction: string,
): string {
  const trimmedTemplate = template.trim();
  if (trimmedTemplate.length === 0) return instruction;
  if (trimmedTemplate.includes("{{instruction}}")) {
    return trimmedTemplate.replace(/\{\{instruction\}\}/g, instruction);
  }
  return `${trimmedTemplate}\n\n${instruction}`.trim();
}
