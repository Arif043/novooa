import {type RelayListCache} from "../../../../shared/local/relay-list-cache.js";
import {type GoogleAccountSummary} from "../../domain/entities/google-account.js";

export const GOOGLE_ACCOUNTS_TOPIC = "google-accounts";

/**
 * Reagiert auf `googleAccountsRevision` im Wake-up-Dokument: Ein Konto wurde verbunden, hat neue Freigaben
 * oder muss neu verbunden werden. Der Cache wird geleert und die Clients laden die Liste neu.
 */
export class GoogleAccountsWakeupHandler {
  private seen = false;
  private revision: unknown;

  constructor(
    private readonly accounts: RelayListCache<GoogleAccountSummary>,
    private readonly publish: (topic: string) => void,
  ) {}

  handle(wakeup: {googleAccountsRevision?: unknown} | undefined): void {
    const changed = this.seen && wakeup?.googleAccountsRevision !== this.revision;
    this.seen = true;
    this.revision = wakeup?.googleAccountsRevision;
    if (changed) this.invalidate();
  }

  /** Der Listener ist gescheitert: Ereignisse könnten fehlen, also nichts Gecachtes behalten. */
  handleFailure(): void {
    this.invalidate();
  }

  private invalidate(): void {
    this.accounts.invalidate();
    this.publish(GOOGLE_ACCOUNTS_TOPIC);
  }
}
