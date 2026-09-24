/**
 * Von jedem realen Transport (aktuell `ws`) erfüllbar, ohne dass dieser
 * Notifier selbst von `ws` abhängen muss — hält die Publish/Subscribe-Logik
 * unabhängig testbar von der tatsächlichen WebSocket-Bibliothek.
 */
export interface LocalRuntimeRealtimeSubscriber {
  send(message: string): void;
}

/**
 * Einfacher In-Memory-Pub/Sub für die Watch-Endpunkte der lokalen Runtime.
 * Kein Multi-Tenant-Aufwand nötig — ein Runtime-Prozess bedient genau einen
 * Arbeitsbereich. Schickt bewusst nur ein leichtes "etwas hat sich geändert"
 * statt der eigentlichen Fachdaten — der Client fragt die bekannten
 * REST-GET-Endpunkte erneut ab (siehe `workspace_realtime_channel.dart`),
 * damit Serialisierung und Parsing an genau einer Stelle bleiben.
 */
export class LocalRuntimeRealtimeNotifier {
  private readonly subscribersByTopic = new Map<string, Set<LocalRuntimeRealtimeSubscriber>>();

  subscribe(topic: string, subscriber: LocalRuntimeRealtimeSubscriber): void {
    const subscribers = this.subscribersByTopic.get(topic) ?? new Set();
    subscribers.add(subscriber);
    this.subscribersByTopic.set(topic, subscribers);
  }

  unsubscribe(topic: string, subscriber: LocalRuntimeRealtimeSubscriber): void {
    this.subscribersByTopic.get(topic)?.delete(subscriber);
  }

  /** Entfernt einen Subscriber aus allen Topics — beim Verbindungsabbau. */
  unsubscribeAll(subscriber: LocalRuntimeRealtimeSubscriber): void {
    for (const subscribers of this.subscribersByTopic.values()) {
      subscribers.delete(subscriber);
    }
  }

  publish(topic: string): void {
    const subscribers = this.subscribersByTopic.get(topic);
    if (subscribers === undefined || subscribers.size === 0) return;
    const message = JSON.stringify({type: "changed", topic});
    for (const subscriber of subscribers) subscriber.send(message);
  }
}
