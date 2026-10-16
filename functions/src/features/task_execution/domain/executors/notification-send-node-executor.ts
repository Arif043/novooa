import {
  executedNode,
  type NodeExecutor,
  type TaskRunContext,
} from "./node-executor.js";

export type NotificationSendSent = {
  teamId: string;
  title: string;
  body: string;
};

export type NotificationSendFailed = {
  teamId: string;
  error: unknown;
};

export type NotificationSendObserver = {
  sent(event: NotificationSendSent): void;
  failed(event: NotificationSendFailed): void;
};

const noopNotificationSendObserver: NotificationSendObserver = {
  sent: () => undefined,
  failed: () => undefined,
};

const defaultTitle = "Benachrichtigung von novooa";

type NotificationSendConfig = {
  title?: string;
  message: string;
};

export function createNotificationSendNodeExecutor(
  observer: NotificationSendObserver = noopNotificationSendObserver,
): NodeExecutor {
  return {
    primitive: "notificationSend",
    async execute(node, runContext) {
      const config = configFrom(node.config);
      const body = runContext.templateExpressionResolver.resolveText(config.message).trim();
      if (!body) throw new Error("Push-Benachrichtigung senden: Text fehlt.");
      const title = titleFrom(config.title, runContext);
      await sendNotification(runContext, title, body, observer);
      // Reiner Seiteneffekt ohne fachlichen Rückgabewert: Der gesendete Text
      // ist dem Graphen durch die eigene Konfiguration bereits bekannt —
      // ihn als Output zu echoen suggeriert einen neuen, referenzierbaren
      // Wert, den es nicht gibt (siehe docs/notes/executor-outputs.md).
      return executedNode(node, {});
    },
  };
}

async function sendNotification(
  runContext: TaskRunContext,
  title: string,
  body: string,
  observer: NotificationSendObserver,
): Promise<void> {
  try {
    await runContext.teamNotificationSender.sendToTeam(runContext.teamId, {
      title,
      body,
      data: {type: "taskNotification"},
    });
  } catch (error) {
    observer.failed({teamId: runContext.teamId, error});
    throw error;
  }
  observer.sent({teamId: runContext.teamId, title, body});
}

function titleFrom(configuredTitle: string | undefined, runContext: TaskRunContext): string {
  const title = runContext.templateExpressionResolver.resolveText(configuredTitle ?? "").trim();
  return title || defaultTitle;
}

function configFrom(config: unknown): NotificationSendConfig {
  if (!isRecord(config)) return {message: ""};
  return {
    title: typeof config.title === "string" ? config.title : undefined,
    message: typeof config.message === "string" ? config.message : "",
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
