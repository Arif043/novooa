import {type OutboundHttpClient} from "../../../connections/domain/repositories/outbound-http-client.js";
import {type InterpretedRun, type WebhookInterpreter} from "../../../webhooks/domain/entities/webhook-interpreter.js";
import {type WebhookRequest} from "../../../webhooks/domain/entities/webhook-event.js";
import {type EventTaskTrigger} from "../../../scheduling/domain/repositories/task-trigger-store.js";
import {ShopwareClient, type ShopwareRecord} from "../infrastructure/shopware-client.js";
import {customerAssociations, mapShopwareCustomer} from "../infrastructure/shopware-customer-mapper.js";
import {mapShopwareNewsletterRecipient, newsletterRecipientAssociations} from "../infrastructure/shopware-newsletter-mapper.js";
import {mapShopwareOrder, orderAssociations} from "../infrastructure/shopware-order-mapper.js";
import {mapShopwareProduct, productAssociations} from "../infrastructure/shopware-product-mapper.js";
import {isRecord, list, record, text} from "../infrastructure/shopware-record.js";
import {
  shopwareTriggerParamsFrom, shopwareWebhookEventName, type ShopwareTriggerEvent, type ShopwareTriggerParams,
} from "./shopware-trigger-params.js";

type Loaded = {id: string; label: string; value: unknown};

/** Ein Import kann tausende Produkte in einem Aufruf melden; mehr als diese Anzahl wird nicht nachgeladen. */
const maximumProductsPerCall = 50;

/**
 * Wertet Aufrufe der Shopware-App aus: prüft, ob das Ereignis zum Auslöser passt, lädt den Datensatz über die
 * Verbindung nach (die Ereignisse tragen je nach Art nur Kennungen) und gibt ihn im einfachen Modell weiter.
 * Die Form der Nutzlast ist aus der Dokumentation übernommen, nicht gegen einen Shop geprüft; deshalb liest dieser
 * Code tolerant und braucht je Ereignis nur die Kennung.
 */
export class ShopwareTriggerInterpreter implements WebhookInterpreter {
  constructor(
    private readonly http: OutboundHttpClient,
    private readonly now: () => Date = () => new Date(),
  ) {}

  async interpret(trigger: EventTaskTrigger, request: WebhookRequest): Promise<InterpretedRun[]> {
    const params = shopwareTriggerParamsFrom(trigger.eventConfig.params);
    const message = messageFrom(request.rawBody);
    if (message === undefined || message.event !== shopwareWebhookEventName(params)) return [];
    const client = new ShopwareClient(this.http, trigger.teamId, params.connectionId);
    const loaded = await this.load(params, message.payload, client);
    const receivedAt = this.now().toISOString();
    return loaded.map((item) => ({
      context: `Shopware: ${item.label}`,
      event: {type: "shopwareEvent", kind: params.event, eventName: message.event, id: item.id, receivedAt, value: item.value},
    }));
  }

  private async load(params: ShopwareTriggerParams, payload: unknown, client: ShopwareClient): Promise<Loaded[]> {
    switch (params.event) {
      case "orderPlaced":
      case "orderStatus": return this.order(params.event, payload, client);
      case "customerRegistered": return this.customer(payload, client);
      case "stockLow": return this.lowStock(params, payload, client);
      case "newsletterSubscribed": return this.newsletter(payload, client);
    }
  }

  private async order(event: ShopwareTriggerEvent, payload: unknown, client: ShopwareClient): Promise<Loaded[]> {
    const data = record(payload);
    const id = firstId(
      idOf(data.order), text(data.orderId), text(record(data.orderTransaction).orderId), text(record(data.orderDelivery).orderId),
    );
    const found = await this.single(client, "order", id, orderAssociations);
    if (found === undefined) return [];
    const order = mapShopwareOrder(found);
    return [{id: order.id, value: order, label: event === "orderPlaced" ? `Neue Bestellung ${order.orderNumber}` : `Bestellung ${order.orderNumber}: Status geändert`}];
  }

  private async customer(payload: unknown, client: ShopwareClient): Promise<Loaded[]> {
    const data = record(payload);
    const found = await this.single(client, "customer", firstId(idOf(data.customer), text(data.customerId)), customerAssociations);
    if (found === undefined) return [];
    const customer = mapShopwareCustomer(found);
    return [{id: customer.id, value: customer, label: `Neuer Kunde ${customer.email}`}];
  }

  private async newsletter(payload: unknown, client: ShopwareClient): Promise<Loaded[]> {
    const data = record(payload);
    const found = await this.single(
      client, "newsletter_recipient", firstId(idOf(data.newsletterRecipient), text(data.newsletterRecipientId)), newsletterRecipientAssociations,
    );
    if (found === undefined) return [];
    const recipient = mapShopwareNewsletterRecipient(found);
    return [{id: recipient.id, value: recipient, label: `Newsletter-Anmeldung ${recipient.email}`}];
  }

  /** `product.written` kommt bei jeder Änderung: gemeldet wird nur, wenn der Bestand betroffen ist und die Grenze erreicht ist. */
  private async lowStock(params: ShopwareTriggerParams, payload: unknown, client: ShopwareClient): Promise<Loaded[]> {
    const ids = changedProductIds(payload).slice(0, maximumProductsPerCall);
    if (ids.length === 0) return [];
    const {data} = await client.search("product", {ids, associations: productAssociations, limit: ids.length});
    return data.map(mapShopwareProduct)
      .filter((product) => product.stock <= params.threshold)
      .map((product) => ({id: product.id, value: product, label: `Bestand niedrig: ${product.name || product.productNumber} (${product.stock})`}));
  }

  private async single(client: ShopwareClient, entity: string, id: string, associations: ShopwareRecord): Promise<ShopwareRecord | undefined> {
    if (id === "") return undefined;
    const {data} = await client.search(entity, {ids: [id], associations, limit: 1});
    return data[0];
  }
}

function messageFrom(raw: Buffer): {event: string; payload: unknown} | undefined {
  let body: unknown;
  try {
    body = JSON.parse(raw.toString("utf8"));
  } catch {
    return undefined;
  }
  const data = record(record(body).data);
  const event = text(data.event) || text(record(body).event);
  if (event === "") return undefined;
  return {event, payload: data.payload ?? record(body).payload};
}

/** Kennungen geänderter Produkte; Einträge, die den Bestand nicht berühren, und Löschungen bleiben außen vor. */
function changedProductIds(payload: unknown): string[] {
  const entries = Array.isArray(payload) ? payload.filter(isRecord) : list(record(payload).payload);
  const ids = new Set<string>();
  for (const entry of entries) {
    if (text(entry.entity) !== "product" || text(entry.operation) === "delete") continue;
    const fields = entry.updatedFields;
    if (Array.isArray(fields) && !fields.includes("stock")) continue;
    const id = text(entry.primaryKey) || text(record(entry.primaryKey).id);
    if (id !== "") ids.add(id);
  }
  return [...ids];
}

function idOf(value: unknown): string {
  return text(record(value).id);
}

function firstId(...candidates: string[]): string {
  return candidates.find((candidate) => candidate !== "") ?? "";
}
