import {type NodeAttachment} from "../entities/attachments.js";
import {
  type StoredTeamFile,
  type TeamFileStore,
  type WriteTeamFileInput,
  type WrittenFile,
} from "../../../files/domain/repositories/team-file-store.js";
import {type PushNotification} from "../../../notifications/domain/entities/push-notification.js";
import {type TeamNotificationSender} from "../../../notifications/domain/repositories/team-notification-sender.js";
import {
  type OutboundHttpClient,
  type OutboundHttpRequest,
  type OutboundHttpResponse,
} from "../../../connections/domain/repositories/outbound-http-client.js";
import {
  type SendTaskMessageInput,
  type SentTaskMessage,
  type TaskMessageSender,
} from "../repositories/task-message-sender.js";
import {type RunEffectRecorder} from "./run-effect-recorder.js";

/**
 * Decorators um die Ports eines Laufs: Sie reichen jeden Aufruf unverändert weiter und
 * zeichnen nach Erfolg einer ändernden Methode einen Effekt auf. So meldet jeder Baustein
 * seine Folgen, ohne sie selbst zu kennen — wie `TriggerChainTeamFileStore`.
 */
export class EffectRecordingTeamFileStore implements TeamFileStore {
  constructor(private readonly inner: TeamFileStore, private readonly effects: RunEffectRecorder) {}

  async writeTeamFile(input: WriteTeamFileInput): Promise<WrittenFile> {
    const file = await this.inner.writeTeamFile(input);
    const {fileId, versionId, displayName, contentType, sizeBytes, isNewFile} = file;
    this.effects.record({kind: "fileWritten", fileId, versionId, displayName, contentType, sizeBytes, isNewFile});
    return file;
  }

  loadTeamFile(teamId: string, fileId: string): Promise<StoredTeamFile> {
    return this.inner.loadTeamFile(teamId, fileId);
  }

  readTextFile(teamId: string, file: NodeAttachment): Promise<string> {
    return this.inner.readTextFile(teamId, file);
  }
}

export class EffectRecordingMessageSender implements TaskMessageSender {
  constructor(private readonly inner: TaskMessageSender, private readonly effects: RunEffectRecorder) {}

  async send(input: SendTaskMessageInput): Promise<SentTaskMessage> {
    const sent = await this.inner.send(input);
    this.effects.record({
      kind: "messageSent", channel: input.kind, recipient: input.recipient,
      ...(input.subject ? {subject: input.subject} : {}),
    });
    return sent;
  }
}

export class EffectRecordingNotificationSender implements TeamNotificationSender {
  constructor(private readonly inner: TeamNotificationSender, private readonly effects: RunEffectRecorder) {}

  async sendToTeam(teamId: string, notification: PushNotification): Promise<void> {
    await this.inner.sendToTeam(teamId, notification);
    this.effects.record({kind: "notificationSent", title: notification.title});
  }
}

export class EffectRecordingHttpClient implements OutboundHttpClient {
  constructor(private readonly inner: OutboundHttpClient, private readonly effects: RunEffectRecorder) {}

  async send(request: OutboundHttpRequest): Promise<OutboundHttpResponse> {
    const response = await this.inner.send(request);
    // Lesen ist keine Folge; nur ändernde Methoden wirken nach außen.
    if (request.method === "GET") return response;
    this.effects.record({
      kind: "httpRequested", method: request.method, status: response.status,
      ...hostOf(request.url),
      ...(request.connectionId ? {connectionId: request.connectionId} : {}),
    });
    return response;
  }
}

/** Nur der Host — Pfad, Query und Fragment können Kennungen oder Schlüssel enthalten. */
function hostOf(url: string): {host?: string} {
  try {
    return {host: new URL(url).host};
  } catch {
    return {};
  }
}
