import {type FastifyInstance} from "fastify";
import {type FileEventPublisher} from "../../features/files/domain/repositories/file-event-publisher.js";
import {type LocalModelCache} from "../../features/machine_learning/infrastructure/local/local-model-cache.js";
import {type RuntimeSystemModelCatalog} from "../../features/machine_learning/infrastructure/local/runtime-system-model-catalog.js";
import {type WebhookReceiver} from "../../features/webhooks/domain/usecases/receive-webhook.js";
import {type TaskWorkflow} from "../../features/task_execution/domain/usecases/task-workflow.js";
import {type ApplicationLogger} from "../logging/application-logger.js";

/**
 * Alles, was vom aktiven Arbeitsbereich abhängt. Routen-Plugins werden
 * einmal beim Start registriert und lesen diesen Kontext pro Anfrage aus
 * `request.workspace` — ein Arbeitsbereichswechsel braucht so keine neuen
 * Routen oder Controller.
 */
export type LocalRuntimeWorkspaceContext = {
  teamId: string;
  userId: string;
  logger: ApplicationLogger;
  taskWorkflow: TaskWorkflow;
  /** Meldet Datei-Ereignisse an die Event-Trigger des Arbeitsbereichs. */
  fileEvents: FileEventPublisher;
  /** Nimmt Aufrufe externer Systeme an und startet die passenden Webhook-Auslöser. */
  webhooks: WebhookReceiver;
  /** Nur vorhanden, wenn die Runtime eine Firebase-Sitzung hat. */
  systemModelCatalog: RuntimeSystemModelCatalog | undefined;
  /** Lädt Katalogmodelle in den lokalen Cache; wie der Katalog nur mit Firebase-Sitzung. */
  modelCache: LocalModelCache | undefined;
};

declare module "fastify" {
  interface FastifyRequest {
    workspace: LocalRuntimeWorkspaceContext;
  }
}

/**
 * Getter-Decorator statt `onRequest`-Hook: Der Kontext wird erst aufgelöst,
 * wenn eine Route ihn liest. Login und Setup brauchen ihn nicht und hängen so
 * nicht davon ab, dass der Arbeitsbereich bereits vollständig läuft. Ohne
 * aktive Lizenz antworten die Lizenz-Hooks ohnehin vorher mit 423.
 */
export function registerWorkspaceContext(
  app: FastifyInstance,
  resolve: () => LocalRuntimeWorkspaceContext,
): void {
  app.decorateRequest("workspace", {getter: resolve});
}
