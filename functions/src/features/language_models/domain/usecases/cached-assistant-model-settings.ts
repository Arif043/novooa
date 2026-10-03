import {type AssistantModelSettings} from "../repositories/assistant-model-settings.js";

const refreshMilliseconds = 5 * 60 * 1000;
const retryAfterFailureMilliseconds = 30 * 1000;

/**
 * Hält den Modellnamen des KI-Agenten fünf Minuten, damit nicht jede Anfrage
 * an die Quelle (Remote Config, Cloud-Relay) geht. Scheitert das Laden, gilt
 * der zuletzt bekannte Wert — zuerst keiner — und nach 30 Sekunden wird
 * erneut versucht. Gleichzeitige Anfragen teilen sich ein Laden.
 */
export class CachedAssistantModelSettings implements AssistantModelSettings {
  private name: string | null = null;
  private validUntil = 0;
  private refreshing: Promise<void> | undefined;

  constructor(
    private readonly load: () => Promise<string | null>,
    private readonly onFailure: (error: unknown) => void = () => undefined,
    private readonly now: () => number = Date.now,
  ) {}

  async modelName(): Promise<string | null> {
    if (this.now() >= this.validUntil) {
      await (this.refreshing ??= this.refresh().finally(() => { this.refreshing = undefined; }));
    }
    return this.name;
  }

  private async refresh(): Promise<void> {
    try {
      this.name = await this.load();
      this.validUntil = this.now() + refreshMilliseconds;
    } catch (error) {
      this.onFailure(error);
      this.validUntil = this.now() + retryAfterFailureMilliseconds;
    }
  }
}
