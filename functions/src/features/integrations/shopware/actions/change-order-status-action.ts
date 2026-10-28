import {changed, jsonField} from "../../external-action-effect.js";
import {type NodeOutputValue} from "../../../task_execution/domain/entities/task.js";
import {type ShopwareAction} from "../domain/shopware-action.js";
import {ShopwareError} from "../domain/shopware-error.js";
import {type ShopwareOrder} from "../domain/shopware-order.js";
import {ShopwareParams} from "../domain/shopware-params.js";
import {type ShopwareClient} from "../infrastructure/shopware-client.js";
import {findOne, referenceFrom} from "../infrastructure/shopware-lookup.js";
import {mapShopwareOrder, orderAssociations} from "../infrastructure/shopware-order-mapper.js";
import {first, list, record, text} from "../infrastructure/shopware-record.js";

/** Übergänge der Zustandsmaschinen von Shopware 6.6, je Bereich (`bereich.übergang`). */
export const orderTransitions = [
  "order.process", "order.complete", "order.cancel", "order.reopen",
  "payment.paid", "payment.paid_partially", "payment.refund", "payment.refund_partially", "payment.cancel",
  "payment.reopen", "payment.remind", "payment.fail", "payment.authorize", "payment.chargeback",
  "delivery.ship", "delivery.ship_partially", "delivery.retour", "delivery.cancel", "delivery.reopen",
] as const;

type Scope = "order" | "payment" | "delivery";
const entities: Record<Scope, string> = {order: "order", payment: "order_transaction", delivery: "order_delivery"};
const scopeLabels: Record<Scope, string> = {order: "Bestellung", payment: "Zahlung", delivery: "Lieferung"};

/**
 * Bestellstatus ändern: Bestellung, jüngste Zahlung oder erste Lieferung. Das ist nicht umkehrbar und kann Mails an den
 * Kunden auslösen (standardmäßig aus).
 */
export const changeOrderStatusAction: ShopwareAction = {
  id: "changeOrderStatus",
  async execute({client, params, resolveText}) {
    const input = new ShopwareParams(params, resolveText);
    const reference = referenceFrom(input, {id: "orderId", number: "orderNumber"}, {id: "Bestell-ID", number: "Bestellnummer"});
    const choice = input.choice("transition", orderTransitions, "Statuswechsel");
    if (choice === "") throw new ShopwareError("Bitte wähle den Statuswechsel.");
    const [scope, transition] = choice.split(".") as [Scope, string];
    const sendMail = input.boolean("sendMail", "Mail an den Kunden senden");

    const raw = await findOne(client, "order", reference, {numberField: "orderNumber", associations: orderAssociations, noun: "Die Bestellung"});
    const before = mapShopwareOrder(raw);
    const targetId = targetIdOf(scope, raw);

    try {
      await client.request("POST", `/api/_action/${entities[scope]}/${targetId}/state/${transition}`, {sendMail});
    } catch (error) {
      throw await explained(error, {client, scope, transition, targetId, current: statusOf(scope, before)});
    }

    const after = mapShopwareOrder(await findOne(client, "order", {id: before.id}, {numberField: "orderNumber", associations: orderAssociations, noun: "Die Bestellung"}));
    const previousStatus = statusOf(scope, before);
    const newStatus = statusOf(scope, after);
    return {
      value: {type: "json", value: after},
      previousStatus: {type: "string", value: previousStatus},
      newStatus: {type: "string", value: newStatus},
      changed: {type: "boolean", value: previousStatus !== newStatus},
    } satisfies Record<string, NodeOutputValue>;
  },
  effectLabel: (outputs) => {
    if (!changed(outputs)) return undefined;
    const status = outputs.newStatus?.type === "string" ? outputs.newStatus.value : "";
    return [jsonField(outputs.value, "orderNumber"), status].filter(Boolean).join(": ") || undefined;
  },
};

function statusOf(scope: Scope, order: ShopwareOrder): string {
  return scope === "order" ? order.status : scope === "payment" ? order.paymentStatus : order.deliveryStatus;
}

function targetIdOf(scope: Scope, order: Record<string, unknown>): string {
  if (scope === "order") return text(order.id);
  // Die Suche sortiert Zahlungen absteigend nach Datum: die erste ist die jüngste.
  const id = text(first(scope === "payment" ? order.transactions : order.deliveries).id);
  if (id === "") throw new ShopwareError(`Die Bestellung hat keine ${scopeLabels[scope]}, deren Status sich ändern ließe.`);
  return id;
}

/** Ein unzulässiger Übergang bekommt die Liste der möglichen dazu; alle anderen Fehler bleiben unverändert. */
async function explained(
  error: unknown,
  context: {client: ShopwareClient; scope: Scope; transition: string; targetId: string; current: string},
): Promise<unknown> {
  if (!(error instanceof ShopwareError) || error.status !== 400) return error;
  let allowed: string[] = [];
  try {
    const {data} = await context.client.request("GET", `/api/_action/state-machine/${entities[context.scope]}/${context.targetId}/state`);
    allowed = list(record(data).transitions).map((entry) => text(entry.actionName)).filter((name) => name !== "");
  } catch {
    // Die Liste ist nur eine Hilfe; die ursprüngliche Meldung bleibt.
  }
  const possible = allowed.length === 0 ? "" : ` Möglich sind: ${allowed.join(", ")}.`;
  return new ShopwareError(
    `Der Statuswechsel „${context.transition}“ ist für die ${scopeLabels[context.scope]} im Status „${context.current}“ nicht möglich.${possible}`,
    error.status,
  );
}
