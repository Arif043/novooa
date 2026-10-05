import {type ShopwareAction} from "../domain/shopware-action.js";
import {ShopwareParams} from "../domain/shopware-params.js";
import {mapShopwareOrder, orderAssociations} from "../infrastructure/shopware-order-mapper.js";

export const orderStatuses = ["open", "in_progress", "completed", "cancelled"] as const;
export const paymentStatuses = [
  "open", "paid", "paid_partially", "refunded", "refunded_partially", "cancelled", "reminded", "failed",
  "authorized", "in_progress", "chargeback", "unconfirmed",
] as const;
export const deliveryStatuses = ["open", "shipped", "shipped_partially", "returned", "returned_partially", "cancelled"] as const;
export const orderSortings = ["newest", "oldest"] as const;

type Filter = Record<string, unknown>;

/** Bestellungen suchen: Zeitraum, Status, Kunde und Bestellnummer; liefert die Liste im einfachen Modell. */
export const searchOrdersAction: ShopwareAction = {
  id: "searchOrders",
  async execute({client, params, resolveText}) {
    const input = new ShopwareParams(params, resolveText);
    const filter: Filter[] = [];
    const from = input.dateTime("createdFrom", "Bestellt ab");
    const to = input.dateTime("createdTo", "Bestellt bis");
    if (from !== "" || to !== "") {
      filter.push({type: "range", field: "createdAt", parameters: {...(from === "" ? {} : {gte: from}), ...(to === "" ? {} : {lte: to})}});
    }
    const equals = (field: string, value: string) => {
      if (value !== "") filter.push({type: "equals", field, value});
    };
    equals("stateMachineState.technicalName", input.choice("status", orderStatuses, "Bestellstatus"));
    equals("transactions.stateMachineState.technicalName", input.choice("paymentStatus", paymentStatuses, "Zahlungsstatus"));
    equals("deliveries.stateMachineState.technicalName", input.choice("deliveryStatus", deliveryStatuses, "Lieferstatus"));
    equals("orderCustomer.email", input.text("customerEmail", 254));
    equals("orderNumber", input.text("orderNumber", 64));
    const sorting = input.choice("sort", orderSortings, "Sortierung") || "newest";
    const limit = input.integer("limit", "Höchstanzahl", {min: 1, max: 500, fallback: 50});

    const result = await client.searchAll("order", {
      filter,
      sort: [{field: "createdAt", order: sorting === "newest" ? "DESC" : "ASC"}],
      associations: orderAssociations,
    }, limit);

    const orders = result.data.map(mapShopwareOrder);
    return {
      value: {type: "json", value: orders},
      count: {type: "number", value: orders.length},
      total: {type: "number", value: result.total},
      found: {type: "boolean", value: orders.length > 0},
    };
  },
};
