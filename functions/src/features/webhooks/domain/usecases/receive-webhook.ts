import {createHash, timingSafeEqual} from "node:crypto";
import {type RateLimiter} from "../../../../shared/rate_limiting/domain/repositories/rate-limiter.js";
import {webhookSecretRef, type WebhookSecretStore} from "../../../scheduling/domain/repositories/webhook-secret-store.js";
import {type EventTaskTrigger} from "../../../scheduling/domain/repositories/task-trigger-store.js";
import {startEventTriggerRun, type EventTriggerRunPorts} from "../../../scheduling/domain/usecases/start-event-trigger-run.js";
import {maximumRunsPerWebhook, type WebhookInterpreter} from "../entities/webhook-interpreter.js";
import {webhookContextText, webhookEventFrom, type WebhookRequest} from "../entities/webhook-event.js";
import {webhookSignatureMatches} from "./verify-webhook-signature.js";

export type WebhookResult =
  | {kind: "accepted"}
  /** Antwort auf die Einrichtungsprüfung des Absenders: den Parameter unverändert zurückgeben. */
  | {kind: "echo"; value: string}
  | {kind: "notFound"}
  | {kind: "badRequest"}
  | {kind: "unauthorized"}
  | {kind: "rateLimited"; retryAfterSeconds: number};

export interface WebhookReceiver {
  receive(request: WebhookRequest): Promise<WebhookResult>;
}

export const unavailableWebhookReceiver: WebhookReceiver = {
  async receive() {
    return {kind: "notFound"};
  },
};

export type ReceiveWebhookPorts = EventTriggerRunPorts & {
  teamId: string;
  secrets: Pick<WebhookSecretStore, "read">;
  /** Wird nur bei Fehlversuchen belastet: schützt vor dem Durchprobieren von Adressen. */
  failures: RateLimiter;
  /** Je Auslöser: schützt die Aufgabe vor einer Flut gültiger Aufrufe. */
  triggers: RateLimiter;
  /** Auslöser anderer Quellen als `webhookReceived` lassen den Aufruf von ihrem Interpreter auswerten. */
  interpreters?: ReadonlyMap<string, WebhookInterpreter>;
  now?: () => Date;
};

const maximumEchoLength = 2048;

export class ReceiveWebhook implements WebhookReceiver {
  constructor(private readonly ports: ReceiveWebhookPorts) {}

  async receive(request: WebhookRequest): Promise<WebhookResult> {
    const trigger = await this.find(request);
    if (trigger === undefined) return this.rejectedAttempt({kind: "notFound"});
    const flood = await this.ports.triggers.take(trigger.id);
    if (!flood.allowed) return {kind: "rateLimited", retryAfterSeconds: flood.retryAfterSeconds};
    return this.accept(trigger, request);
  }

  private async find(request: WebhookRequest): Promise<EventTaskTrigger | undefined> {
    const triggers = await this.ports.triggerStore.listEnabledEventTriggers(this.ports.teamId);
    const trigger = triggers.find((candidate) => candidate.id === request.triggerId);
    const expected = trigger?.eventConfig.webhook?.token;
    if (trigger === undefined || expected === undefined || expected.length === 0) return undefined;
    return tokensMatch(expected, request.token) ? trigger : undefined;
  }

  private async rejectedAttempt(result: WebhookResult): Promise<WebhookResult> {
    const attempt = await this.ports.failures.take("fehlversuche");
    return attempt.allowed ? result : {kind: "rateLimited", retryAfterSeconds: attempt.retryAfterSeconds};
  }

  private async accept(trigger: EventTaskTrigger, request: WebhookRequest): Promise<WebhookResult> {
    const webhook = trigger.eventConfig.webhook;
    if (webhook === undefined) return this.rejectedAttempt({kind: "notFound"});
    const handshake = webhook.validationParameter.length === 0 ? undefined : request.query[webhook.validationParameter];
    if (handshake !== undefined) {
      return handshake.length > maximumEchoLength ? {kind: "badRequest"} : {kind: "echo", value: handshake};
    }
    if (request.method === "GET") return this.rejectedAttempt({kind: "notFound"});
    const signatureHeader = await this.verifiedSignatureHeader(trigger, request);
    if (signatureHeader === null) return {kind: "unauthorized"};
    const interpreter = this.ports.interpreters?.get(trigger.eventConfig.source);
    if (interpreter !== undefined) {
      const runs = await interpreter.interpret(trigger, request);
      for (const run of runs.slice(0, maximumRunsPerWebhook)) await startEventTriggerRun(trigger, run, this.ports);
      return {kind: "accepted"};
    }
    const event = webhookEventFrom(request, signatureHeader, (this.ports.now ?? (() => new Date()))());
    await startEventTriggerRun(trigger, {context: webhookContextText(event, request.rawBody.length), event}, this.ports);
    return {kind: "accepted"};
  }

  /** `undefined`: keine Prüfung konfiguriert; `null`: Prüfung fehlgeschlagen; sonst der Name der Signatur-Kopfzeile. */
  private async verifiedSignatureHeader(trigger: EventTaskTrigger, request: WebhookRequest): Promise<string | undefined | null> {
    const verification = trigger.eventConfig.webhook?.verification;
    if (verification === undefined || verification.kind === "none") return undefined;
    const secret = await this.ports.secrets.read(webhookSecretRef(trigger.teamId, trigger.id));
    if (secret === null) return null;
    return webhookSignatureMatches(verification, secret, request.rawBody, request.headers[verification.header])
      ? verification.header
      : null;
  }
}

/** Über SHA-256 auf gleiche Länge gebracht, damit der Vergleich weder Länge noch Inhalt verrät. */
function tokensMatch(expected: string, given: string): boolean {
  return timingSafeEqual(createHash("sha256").update(expected).digest(), createHash("sha256").update(given).digest());
}
