import {type EventTriggerConfig} from "./event-trigger-config.js";
import {generateWebhookToken, webhookConfigFrom} from "./webhook-config.js";

export type EventTriggerSourceDefinition = {
  id: string;
  /** Ergänzt serverseitig, was der Client nicht vorgeben darf (z. B. ein Webhook-Token). */
  prepare?: (config: EventTriggerConfig) => EventTriggerConfig;
  /** Der Auslöser wird über eine Adresse mit Token aufgerufen (Webhook-Empfänger). */
  usesWebhook?: boolean;
  /** Meldung für unbrauchbare Einstellungen, sonst `null`; geprüft vor `prepare`. */
  problem?: (config: EventTriggerConfig) => string | null;
};

/**
 * Offen für neue Ereignisquellen: Ein Modul meldet seine Quelle hier an, statt eine zentrale
 * Liste zu ändern. Wie das Ereignis entsteht und welche Trigger es startet, bleibt Sache des Moduls.
 */
export class EventTriggerSourceRegistry {
  private readonly definitions = new Map<string, EventTriggerSourceDefinition>();

  register(definition: EventTriggerSourceDefinition): this {
    this.definitions.set(definition.id, definition);
    return this;
  }

  has(id: string): boolean {
    return this.definitions.has(id);
  }

  usesWebhook(id: string): boolean {
    return this.definitions.get(id)?.usesWebhook === true;
  }

  problem(config: EventTriggerConfig): string | null {
    return this.definitions.get(config.source)?.problem?.(config) ?? null;
  }

  prepare(config: EventTriggerConfig): EventTriggerConfig {
    return this.definitions.get(config.source)?.prepare?.(config) ?? config;
  }
}

export function createDefaultEventTriggerSourceRegistry(): EventTriggerSourceRegistry {
  return new EventTriggerSourceRegistry()
    // Kommunikation
    .register({id: "emailReceived"})
    .register({id: "smsMessageReceived"})
    .register({id: "whatsappMessageReceived"})
    // Dateien
    .register({id: "fileCreated"})
    .register({id: "fileVersionCreated"})
    .register({id: "fileDeleted"})
    // Webhooks
    // Das Token vergibt immer der Server, nie der Client.
    .register({
      id: "webhookReceived",
      usesWebhook: true,
      prepare: (config) => ({...config, webhook: {...webhookConfigFrom(config.webhook), token: generateWebhookToken()}}),
    });
}

export const defaultEventTriggerSources = createDefaultEventTriggerSourceRegistry();
