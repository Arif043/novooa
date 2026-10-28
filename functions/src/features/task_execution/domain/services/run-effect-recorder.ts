import {type RunEffect, type RunEffectDetails} from "../entities/run-effect.js";

/**
 * Sammelt die Effekte eines Bausteins. Ein Kind (innerer Baustein eines Zweigs oder einer
 * Schleife) schreibt bei sich und reicht an seine Eltern weiter, damit der umschließende
 * Baustein alle Folgen seines Teilgraphen kennt (Chain of Responsibility).
 */
export class RunEffectRecorder {
  private readonly recorded: RunEffect[] = [];

  private constructor(
    private readonly sourceNodeId: string | null,
    private readonly iteration: number | undefined,
    private readonly parent: RunEffectRecorder | null,
  ) {}

  /** Wurzel eines Laufs; zeichnet nichts selbst auf, sondern nimmt nur von Kindern an. */
  static root(): RunEffectRecorder {
    return new RunEffectRecorder(null, undefined, null);
  }

  /** Ohne eigene Runde erbt das Kind die Runde der Eltern. */
  child(nodeId: string, iteration?: number): RunEffectRecorder {
    return new RunEffectRecorder(nodeId, iteration ?? this.iteration, this);
  }

  record(details: RunEffectDetails): void {
    if (this.sourceNodeId === null) throw new Error("Die Wurzel kennt keinen verursachenden Baustein.");
    this.accept({
      ...details,
      sourceNodeId: this.sourceNodeId,
      ...(this.iteration === undefined ? {} : {iteration: this.iteration}),
    });
  }

  /**
   * Übernimmt Effekte eines Ergebnisses aus einem früheren Versuch (Journal), damit auch der
   * umschließende Baustein sie kennt; Herkunft und Runde bleiben, wie sie waren.
   */
  adopt(effects: readonly RunEffect[]): void {
    for (const effect of effects) this.accept(effect);
  }

  get effects(): readonly RunEffect[] {
    return this.recorded;
  }

  private accept(effect: RunEffect): void {
    this.recorded.push(effect);
    this.parent?.accept(effect);
  }
}
