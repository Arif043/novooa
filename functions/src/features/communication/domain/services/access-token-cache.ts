/**
 * Merkt sich Zugriffstokens je Connector bis kurz vor ihrem Ablauf, damit nicht
 * jede Mail und jeder Sendevorgang ein neues Token beim Anbieter abholt. Der
 * Speicher lebt nur im Prozess; eine andere Instanz holt sich bei Bedarf ein eigenes.
 */
export class AccessTokenCache {
  private readonly entries = new Map<string, {accessToken: string; expiresAt: number}>();

  constructor(private readonly safetyMarginMilliseconds = 60_000, private readonly maxEntries = 500) {}

  get(connectorId: string, now: number): string | null {
    const entry = this.entries.get(connectorId);
    if (entry === undefined) return null;
    if (entry.expiresAt - this.safetyMarginMilliseconds <= now) {
      this.entries.delete(connectorId);
      return null;
    }
    return entry.accessToken;
  }

  set(connectorId: string, accessToken: string, expiresAt: number): void {
    this.entries.delete(connectorId);
    this.entries.set(connectorId, {accessToken, expiresAt});
    while (this.entries.size > this.maxEntries) {
      const oldest = this.entries.keys().next().value as string;
      this.entries.delete(oldest);
    }
  }

  delete(connectorId: string): void {
    this.entries.delete(connectorId);
  }
}
