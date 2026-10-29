import {z, type ToolAction} from "genkit";
import {type GenkitBeta} from "genkit/beta";
import {DelegationBudget} from "../../../../../assistant/infrastructure/genkit/subagents/delegation-budget.js";
import {type EmployeeConversation} from "../../runner/employee-conversation.js";
import {maximumDelegations, memberTaskPrompt, type TeamMemberTool, type TeamworkTask} from "./teamwork-prompts.js";
import {type TeamworkTranscript} from "./teamwork-transcript.js";

/** Ein Mitarbeiter, bereit zur Arbeit: sein Gespräch für diesen Lauf (Modell, Arbeitsordner, Fähigkeiten). */
export type TeamMemberRun = TeamMemberTool & {conversation: EmployeeConversation};

const delegationInputSchema = z.object({
  task: z.string().describe("What the employee should do, with the necessary context; understandable on its own."),
  expectedResult: z.string().describe("What exactly should come back: content, scope, form and, if applicable, a file path under shared/."),
  boundaries: z.string().optional().describe("What is not part of the assignment or has already been done."),
});

const delegationOutputSchema = z.object({response: z.string()});

/**
 * Macht jeden Mitarbeiter zu einem Werkzeug des Orchestrators. Der Mitarbeiter läuft in der Genkit-Instanz
 * seines eigenen Modells, deshalb eigene Werkzeuge statt der `agents`-Middleware, die Agenten nur in der
 * Registry des Orchestrators findet. Das Budget gilt für den ganzen Lauf, auch für Nachbesserungen.
 * Fehler gehen als Antwort zurück, damit der Orchestrator weiterarbeitet.
 */
export function delegationToolsFor(ai: GenkitBeta, runs: TeamMemberRun[], transcript: TeamworkTranscript): ToolAction[] {
  const budget = new DelegationBudget(maximumDelegations);
  return runs.map((run) => ai.dynamicTool(
    {
      name: run.toolName,
      description: `${run.employeeName}: ${run.responsibility}`,
      inputSchema: delegationInputSchema,
      outputSchema: delegationOutputSchema,
    },
    async (task) => {
      if (!budget.tryConsume()) {
        return {response: "Das Auftragsbudget ist aufgebraucht. Schließe die Aufgabe mit den vorhandenen Ergebnissen ab."};
      }
      return delegate(run, task, transcript);
    },
  ) as ToolAction);
}

async function delegate(run: TeamMemberRun, task: TeamworkTask, transcript: TeamworkTranscript): Promise<{response: string}> {
  const member = {id: run.employeeId, name: run.employeeName};
  transcript.task(member, task);
  const startedAt = Date.now();
  try {
    const answer = await run.conversation.send(memberTaskPrompt(task));
    transcript.answer(member, answer, Date.now() - startedAt);
    return {response: answer.trim() || "(keine Antwort)"};
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    transcript.failure(member, message);
    return {response: `Der Auftrag an ${run.employeeName} ist gescheitert: ${message}`};
  }
}
