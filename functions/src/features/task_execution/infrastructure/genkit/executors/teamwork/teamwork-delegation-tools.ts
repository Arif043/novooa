import {z, type ToolAction} from "genkit";
import {type GenkitBeta} from "genkit/beta";
import {type ApplicationLogger} from "../../../../../../shared/logging/application-logger.js";
import {DelegationBudget} from "../../../../../assistant/infrastructure/genkit/subagents/delegation-budget.js";
import {type EmployeeConversation} from "../../runner/employee-conversation.js";
import {formatDelegationAnswer, formatDelegationFailure, formatDelegationTask} from "./teamwork-log-format.js";
import {maximumDelegations, memberTaskPrompt, type TeamMemberTool, type TeamworkTask} from "./teamwork-prompts.js";

/** Ein Mitarbeiter, bereit zur Arbeit: sein Gespräch für diesen Lauf (Modell, Arbeitsordner, Fähigkeiten). */
export type TeamMemberRun = TeamMemberTool & {conversation: EmployeeConversation};

const delegationInputSchema = z.object({
  task: z.string().describe("Was der Mitarbeiter tun soll, mit dem nötigen Kontext; für sich verständlich."),
  expectedResult: z.string().describe("Was genau zurückkommen soll: Inhalt, Umfang, Form, ggf. Dateipfad unter shared/."),
  boundaries: z.string().optional().describe("Was nicht zum Auftrag gehört oder schon erledigt ist."),
});

const delegationOutputSchema = z.object({response: z.string()});

/**
 * Macht jeden Mitarbeiter zu einem Werkzeug des Orchestrators. Der Mitarbeiter läuft in der Genkit-Instanz
 * seines eigenen Modells, deshalb eigene Werkzeuge statt der `agents`-Middleware, die Agenten nur in der
 * Registry des Orchestrators findet. Das Budget gilt für den ganzen Lauf, auch für Nachbesserungen.
 * Fehler gehen als Antwort zurück, damit der Orchestrator weiterarbeitet.
 */
export function delegationToolsFor(ai: GenkitBeta, runs: TeamMemberRun[], logger: ApplicationLogger): ToolAction[] {
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
      return delegate(run, task, logger);
    },
  ) as ToolAction);
}

async function delegate(run: TeamMemberRun, task: TeamworkTask, logger: ApplicationLogger): Promise<{response: string}> {
  logger.readableInfo(formatDelegationTask(run.employeeName, task));
  const startedAt = Date.now();
  try {
    const answer = await run.conversation.send(memberTaskPrompt(task));
    logger.readableInfo(formatDelegationAnswer(run.employeeName, answer, Date.now() - startedAt));
    return {response: answer.trim() || "(keine Antwort)"};
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.readableError(formatDelegationFailure(run.employeeName, message));
    return {response: `Der Auftrag an ${run.employeeName} ist gescheitert: ${message}`};
  }
}
