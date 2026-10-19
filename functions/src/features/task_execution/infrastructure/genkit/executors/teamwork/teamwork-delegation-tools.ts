import {z, type GenerateOptions, type ToolAction} from "genkit";
import {type GenkitBeta} from "genkit/beta";
import {type ApplicationLogger} from "../../../../../../shared/logging/application-logger.js";
import {DelegationBudget} from "../../../../../assistant/infrastructure/genkit/subagents/delegation-budget.js";
import {runEmployeeAgentTurn} from "../../runner/employee-agent.js";
import {type ResolvedTeamMember} from "../../runner/teamwork-workspace.js";
import {formatDelegationAnswer, formatDelegationFailure, formatDelegationTask} from "./teamwork-log-format.js";
import {type TeamworkModel} from "./teamwork-model.js";
import {maximumDelegations, memberTaskPrompt, type TeamMemberTool} from "./teamwork-prompts.js";

/** Ein Mitarbeiter, bereit zur Arbeit: sein Modell und seine Middleware (Arbeitsordner, Fähigkeiten). */
export type TeamMemberRun = TeamMemberTool & {
  member: ResolvedTeamMember;
  model: TeamworkModel;
  use: NonNullable<GenerateOptions["use"]>;
};

const delegationOutputSchema = z.object({response: z.string()});

/**
 * Macht jeden Mitarbeiter zu einem Werkzeug des Orchestrators. Der Mitarbeiter läuft in der Genkit-Instanz
 * seines eigenen Modells, deshalb eigene Werkzeuge statt der `agents`-Middleware, die Agenten nur in der
 * Registry des Orchestrators findet. Fehler gehen als Antwort zurück, damit der Orchestrator weiterarbeitet.
 */
export function delegationToolsFor(ai: GenkitBeta, runs: TeamMemberRun[], logger: ApplicationLogger): ToolAction[] {
  const budget = new DelegationBudget(maximumDelegations);
  return runs.map((run) => ai.dynamicTool(
    {
      name: run.toolName,
      description: `${run.employeeName}: ${run.responsibility}`,
      inputSchema: z.object({task: z.string().describe("Ein für sich verständlicher Auftrag mit Ziel und Kontext.")}),
      outputSchema: delegationOutputSchema,
    },
    async ({task}) => {
      if (!budget.tryConsume()) {
        return {response: "Das Auftragsbudget ist aufgebraucht. Schließe die Aufgabe mit den vorhandenen Ergebnissen ab."};
      }
      return delegate(run, task, logger);
    },
  ) as ToolAction);
}

async function delegate(run: TeamMemberRun, task: string, logger: ApplicationLogger): Promise<{response: string}> {
  logger.readableInfo(formatDelegationTask(run.employeeName, task));
  const startedAt = Date.now();
  try {
    const answer = await runEmployeeAgentTurn(run.model.ai, {
      employee: run.member.employee, model: run.model.model, prompt: memberTaskPrompt(task),
      use: run.use, config: run.model.config,
    });
    logger.readableInfo(formatDelegationAnswer(run.employeeName, answer.text, Date.now() - startedAt));
    return {response: answer.text.trim() || "(keine Antwort)"};
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.readableError(formatDelegationFailure(run.employeeName, message));
    return {response: `Der Auftrag an ${run.employeeName} ist gescheitert: ${message}`};
  }
}
