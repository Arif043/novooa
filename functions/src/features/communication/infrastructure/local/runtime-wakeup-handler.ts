import {type MailConnectorListCache} from "./mail-connector-list-cache.js";

export type RuntimeWakeup = {communicationRevision?: unknown; connectorsRevision?: unknown};

export const MAIL_CONNECTORS_TOPIC = "mail-connectors";

/**
 * Reagiert auf das Wake-up-Dokument der Cloud. Es trägt zwei Revisionen: Neue
 * Mails holt der Mail-Worker ab; eine geänderte Postfachliste leert den Cache
 * und sagt den verbundenen Clients per Realtime-Kanal, dass sie neu laden
 * sollen. Der erste Stand nach dem Start holt nur Mails (es kann noch etwas
 * in der Warteschlange liegen), die Liste ist dann ohnehin leer.
 */
export class RuntimeWakeupHandler {
  private seen = false;
  private communicationRevision: unknown;
  private connectorsRevision: unknown;

  constructor(
    private readonly processMail: () => void,
    private readonly connectors: MailConnectorListCache,
    private readonly publish: (topic: string) => void,
  ) {}

  handle(wakeup: RuntimeWakeup | undefined): void {
    const connectorsChanged = this.seen && wakeup?.connectorsRevision !== this.connectorsRevision;
    const mailChanged = !this.seen || wakeup?.communicationRevision !== this.communicationRevision;
    this.seen = true;
    this.communicationRevision = wakeup?.communicationRevision;
    this.connectorsRevision = wakeup?.connectorsRevision;
    if (connectorsChanged) this.invalidateConnectors();
    if (mailChanged) this.processMail();
  }

  /** Der Listener ist gescheitert: Ereignisse könnten fehlen, also nichts Gecachtes behalten. */
  handleFailure(): void {
    this.invalidateConnectors();
  }

  private invalidateConnectors(): void {
    this.connectors.invalidate();
    this.publish(MAIL_CONNECTORS_TOPIC);
  }
}
