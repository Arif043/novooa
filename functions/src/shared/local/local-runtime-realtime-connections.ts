/** Schließcode, wenn die Sitzung einer Realtime-Verbindung endet (abgemeldet, widerrufen, abgelaufen, Lizenz weg). */
export const realtimeSessionEndedCode = 4401;
const sessionEndedReason = "Sitzung beendet";
const defaultSweepIntervalMs = 60 * 1000;

export type RealtimeConnection = {close(code: number, reason: string): void};

/**
 * Offene Realtime-Verbindungen mit der Sitzung, die sie aufgebaut hat. Das
 * Ticket prüft die Sitzung nur beim Verbindungsaufbau; danach sorgt dieses
 * Register dafür, dass eine Verbindung nicht länger lebt als ihre Sitzung.
 */
export class LocalRuntimeRealtimeConnections {
  private readonly sessionByConnection = new Map<RealtimeConnection, string>();

  add(connection: RealtimeConnection, sessionToken: string): void {
    this.sessionByConnection.set(connection, sessionToken);
  }

  remove(connection: RealtimeConnection): void {
    this.sessionByConnection.delete(connection);
  }

  closeSession(sessionToken: string): void {
    this.closeWhere((token) => token === sessionToken);
  }

  /** Schließt alle Verbindungen, deren Sitzung [isAllowed] nicht mehr zulässt. */
  async closeInactive(isAllowed: (sessionToken: string) => Promise<boolean>): Promise<void> {
    const tokens = new Set(this.sessionByConnection.values());
    const ended = new Set<string>();
    for (const token of tokens) if (!await isAllowed(token)) ended.add(token);
    this.closeWhere((token) => ended.has(token));
  }

  get size(): number {
    return this.sessionByConnection.size;
  }

  private closeWhere(matches: (sessionToken: string) => boolean): void {
    for (const [connection, token] of this.sessionByConnection) {
      if (!matches(token)) continue;
      this.sessionByConnection.delete(connection);
      connection.close(realtimeSessionEndedCode, sessionEndedReason);
    }
  }
}

export type RealtimeSessionGuardOptions = {
  connections: LocalRuntimeRealtimeConnections;
  isSessionActive: (sessionToken: string) => Promise<boolean>;
  isLicenseActive: () => boolean;
  intervalMs?: number;
  onFailure?: (error: unknown) => void;
};

/** Prüft offene Verbindungen regelmäßig auf abgelaufene Sitzungen und eine weggefallene Lizenz. */
export class RealtimeSessionGuard {
  private timer: NodeJS.Timeout | undefined;

  constructor(private readonly options: RealtimeSessionGuardOptions) {}

  start(): void {
    if (this.timer !== undefined) return;
    this.timer = setInterval(() => void this.sweep(), this.options.intervalMs ?? defaultSweepIntervalMs);
    this.timer.unref();
  }

  stop(): void {
    clearInterval(this.timer);
    this.timer = undefined;
  }

  async sweep(): Promise<void> {
    const {connections, isSessionActive, isLicenseActive} = this.options;
    try {
      await connections.closeInactive(async (token) => isLicenseActive() && await isSessionActive(token));
    } catch (error) {
      this.options.onFailure?.(error);
    }
  }
}
