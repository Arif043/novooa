/**
 * Ein Graph (Haupt- oder Teilgraph) eines Runs, in dem Schritt-Keys vergeben werden.
 *
 * Eingebettete Graphen (z. B. Schleifen) hängen den Container-Baustein und den Index seines
 * Aufrufs an, damit jede Iteration — auch in verschachtelten Schleifen — eindeutig ist.
 */
export class TaskRunStepScope {
  private constructor(
    readonly teamId: string,
    readonly runId: string,
    readonly path: string,
  ) {}

  static root(teamId: string, runId: string): TaskRunStepScope {
    return new TaskRunStepScope(teamId, runId, "");
  }

  forNode(nodeId: string): TaskRunStepKey {
    return new TaskRunStepKey(this.teamId, this.runId, this.path === "" ? nodeId : `${this.path}/${nodeId}`);
  }

  static nestedIn(key: TaskRunStepKey, callIndex: number): TaskRunStepScope {
    return new TaskRunStepScope(key.teamId, key.runId, `${key.stepPath}:${callIndex}`);
  }
}

/**
 * Adresse eines Baustein-Schritts innerhalb eines Runs und zugleich sein Idempotency-Key.
 *
 * Der Pfad ist deterministisch: Wird ein Run nach einem Absturz wiederholt, erhält derselbe
 * Schritt denselben Key und sein bereits gespeichertes Ergebnis wird übernommen.
 */
export class TaskRunStepKey {
  constructor(
    readonly teamId: string,
    readonly runId: string,
    readonly stepPath: string,
  ) {}

  /** Geltungsbereich des [callIndex]-ten Teilgraphen, den dieser Baustein ausführt. */
  nested(callIndex: number): TaskRunStepScope {
    return TaskRunStepScope.nestedIn(this, callIndex);
  }
}
