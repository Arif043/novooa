import {isRecord} from "../infrastructure/shopware-record.js";

export const shopwareTriggerEvents = ["orderPlaced", "orderStatus", "customerRegistered", "stockLow", "newsletterSubscribed"] as const;
export type ShopwareTriggerEvent = (typeof shopwareTriggerEvents)[number];

/** Die drei Statusabläufe einer Bestellung; die Werte sind die technischen Namen der Zustände in Shopware. */
export const shopwareStateScopes = {
  order: ["open", "in_progress", "completed", "cancelled"],
  order_transaction: [
    "open", "authorized", "paid", "paid_partially", "refunded", "refunded_partially", "cancelled", "failed",
    "reminded", "unconfirmed", "chargeback", "in_progress",
  ],
  order_delivery: ["open", "shipped", "shipped_partially", "returned", "returned_partially", "cancelled"],
} as const;
export type ShopwareStateScope = keyof typeof shopwareStateScopes;

/** Einstellungen eines Shopware-Auslösers (`eventConfig.params`). */
export type ShopwareTriggerParams = {
  event: ShopwareTriggerEvent;
  connectionId: string;
  /** Nur bei `orderStatus`. */
  scope: ShopwareStateScope;
  state: string;
  /** Nur bei `stockLow`: gemeldet wird ab diesem Bestand abwärts. */
  threshold: number;
  /** Nur bei `newsletterSubscribed`: erst nach Bestätigung (Double-Opt-in) melden. */
  confirmedOnly: boolean;
};

const idPattern = /^[A-Za-z0-9_-]{1,100}$/;

/** Tolerant beim Lesen; streng prüft `shopwareTriggerProblem`. */
export function shopwareTriggerParamsFrom(value: unknown): ShopwareTriggerParams {
  const data = isRecord(value) ? value : {};
  const scope = Object.keys(shopwareStateScopes).find((key): key is ShopwareStateScope => key === data.scope) ?? "order_transaction";
  return {
    event: shopwareTriggerEvents.find((event) => event === data.event) ?? "orderPlaced",
    connectionId: typeof data.connectionId === "string" ? data.connectionId.trim() : "",
    scope,
    state: typeof data.state === "string" ? data.state : "",
    threshold: typeof data.threshold === "number" && Number.isFinite(data.threshold) ? Math.trunc(data.threshold) : 0,
    confirmedOnly: data.confirmedOnly !== false,
  };
}

export function shopwareTriggerProblem(value: unknown): string | null {
  const data = isRecord(value) ? value : {};
  if (!shopwareTriggerEvents.some((event) => event === data.event)) return "Das Shopware-Ereignis ist unbekannt.";
  const params = shopwareTriggerParamsFrom(value);
  if (!idPattern.test(params.connectionId)) return "Bitte wähle die Verbindung zu deinem Shopware-Shop.";
  if (params.event === "orderStatus") {
    if (!Object.keys(shopwareStateScopes).includes(String(data.scope))) return "Der Statusbereich ist unbekannt.";
    if (!(shopwareStateScopes[params.scope] as readonly string[]).includes(params.state)) return "Der Zielstatus ist unbekannt.";
  }
  if (params.event === "stockLow" && (params.threshold < -1_000_000 || params.threshold > 1_000_000_000)) {
    return "Die Bestandsgrenze ist ungültig.";
  }
  return null;
}

/** Der Name des Ereignisses, auf das die Shopware-App lauscht (Webhook-Ereignis). */
export function shopwareWebhookEventName(params: ShopwareTriggerParams): string {
  switch (params.event) {
    case "orderPlaced": return "checkout.order.placed";
    case "orderStatus": return `state_enter.${params.scope}.state.${params.state}`;
    case "customerRegistered": return "checkout.customer.register";
    case "stockLow": return "product.written";
    case "newsletterSubscribed": return params.confirmedOnly ? "newsletter.confirmed" : "newsletter.register";
  }
}
