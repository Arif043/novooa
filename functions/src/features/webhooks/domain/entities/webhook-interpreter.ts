import {type EventTaskTrigger} from "../../../scheduling/domain/repositories/task-trigger-store.js";
import {type WebhookRequest} from "./webhook-event.js";

/** Ein Lauf, den ein Aufruf auslöst: lesbarer Text und strukturiertes Ereignis (`input.event`). */
export type InterpretedRun = {context: string; event: unknown};

/**
 * Wertet einen geprüften Aufruf für Auslöser einer bestimmten Quelle aus. Ohne Ergebnis startet nichts (z. B. ein
 * Ereignis, das der Auslöser nicht meint); Fehler führen zu einer Fehlerantwort, damit der Absender es erneut versucht.
 */
export interface WebhookInterpreter {
  interpret(trigger: EventTaskTrigger, request: WebhookRequest): Promise<InterpretedRun[]>;
}

/** Ein Aufruf startet höchstens so viele Läufe, auch wenn er mehrere Treffer enthält. */
export const maximumRunsPerWebhook = 10;
