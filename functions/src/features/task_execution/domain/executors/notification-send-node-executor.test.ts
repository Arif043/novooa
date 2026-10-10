import assert from "node:assert/strict";
import test from "node:test";
import {createNotificationSendNodeExecutor} from "./notification-send-node-executor.js";
import {type TaskRunContext} from "./node-executor.js";
import {type PushNotification} from "../../../notifications/domain/entities/push-notification.js";
import {type TeamNotificationSender} from "../../../notifications/domain/repositories/team-notification-sender.js";

test("sendet den aufgelösten Text als Push-Benachrichtigung an das Team", async () => {
  const sender = new RecordingTeamNotificationSender();
  const executor = createNotificationSendNodeExecutor();

  const result = await executor.execute(
    notificationNode({title: "Status", message: "{{ergebnis}}"}),
    runContext(sender, {"{{ergebnis}}": "Fertig!"}),
  );

  assert.equal(sender.calls.length, 1);
  assert.equal(sender.calls[0]?.teamId, "team_1");
  assert.deepEqual(sender.calls[0]?.notification, {
    title: "Status",
    body: "Fertig!",
    data: {type: "taskNotification"},
  });
  assert.deepEqual(
    result.outputs,
    {},
    "reiner Seiteneffekt ohne fachlichen Rückgabewert — kein Output",
  );
});

test("verwendet einen Standardtitel, wenn keiner konfiguriert ist", async () => {
  const sender = new RecordingTeamNotificationSender();
  const executor = createNotificationSendNodeExecutor();

  await executor.execute(
    notificationNode({message: "Hallo Team"}),
    runContext(sender),
  );

  assert.equal(sender.calls[0]?.notification.title, "Benachrichtigung von novooa");
});

test("schlägt fehl, wenn der aufgelöste Text leer ist", async () => {
  const sender = new RecordingTeamNotificationSender();
  const executor = createNotificationSendNodeExecutor();

  await assert.rejects(
    () => executor.execute(notificationNode({message: "   "}), runContext(sender)),
    /Text fehlt/,
  );
  assert.equal(sender.calls.length, 0);
});

test("informiert den Observer über einen Zustellfehler und wirft weiter", async () => {
  const sender = new FailingTeamNotificationSender();
  const failures: unknown[] = [];
  const executor = createNotificationSendNodeExecutor({
    sent: () => undefined,
    failed: (event) => failures.push(event.error),
  });

  await assert.rejects(
    () => executor.execute(notificationNode({message: "Hallo"}), runContext(sender)),
  );
  assert.equal(failures.length, 1);
});

function notificationNode(config: {title?: string; message: string}) {
  return {
    id: "notify",
    primitive: "notificationSend" as const,
    title: "Push senden",
    description: "",
    outputs: [{key: "value", name: "notify", showOnCanvas: true}],
    config: {primitive: "notificationSend" as const, ...config},
  };
}

function runContext(
  teamNotificationSender: TeamNotificationSender,
  templateValues: Record<string, unknown> = {},
): TaskRunContext {
  return {
    teamId: "team_1",
    teamNotificationSender,
    templateExpressionResolver: {
      resolveText: (template: string) => templateValues[template] as string ?? template,
    },
  } as TaskRunContext;
}

class RecordingTeamNotificationSender implements TeamNotificationSender {
  calls: {teamId: string; notification: PushNotification}[] = [];

  async sendToTeam(teamId: string, notification: PushNotification): Promise<void> {
    this.calls.push({teamId, notification});
  }
}

class FailingTeamNotificationSender implements TeamNotificationSender {
  async sendToTeam(): Promise<void> {
    throw new Error("Relay nicht erreichbar");
  }
}
