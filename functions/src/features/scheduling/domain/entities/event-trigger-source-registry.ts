import {type EventTriggerConfig} from "./event-trigger-config.js";

export type EventTriggerSourceDefinition = {
  id: string;
  /** Ergänzt serverseitig, was der Client nicht vorgeben darf (z. B. ein Webhook-Token). */
  prepare?: (config: EventTriggerConfig) => EventTriggerConfig;
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
    .register({id: "webhookReceived"});
}

export const defaultEventTriggerSources = createDefaultEventTriggerSourceRegistry();
