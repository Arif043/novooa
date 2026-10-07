/**
 * Begrenzt, wie oft der Orchestrator innerhalb einer Anfrage an Subagenten
 * delegieren darf. Jede Delegation ist ein eigener Modellaufruf; ohne Grenze
 * könnte ein Modell in Schleifen geraten und das Relay-Timeout reißen.
 */
export class DelegationBudget {
  private used = 0;

  constructor(private readonly maxDelegations: number) {
    if (!Number.isInteger(maxDelegations) || maxDelegations < 1) {
      throw new Error("Das Delegationsbudget muss mindestens 1 betragen.");
    }
  }

  tryConsume(): boolean {
    if (this.used >= this.maxDelegations) return false;
    this.used += 1;
    return true;
  }
}
