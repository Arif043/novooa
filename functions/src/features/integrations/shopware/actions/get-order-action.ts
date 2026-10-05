import {type ShopwareAction} from "../domain/shopware-action.js";
import {ShopwareParams} from "../domain/shopware-params.js";
import {findOne, referenceFrom} from "../infrastructure/shopware-lookup.js";
import {mapShopwareOrder, orderAssociations} from "../infrastructure/shopware-order-mapper.js";

/** Eine Bestellung über Nummer oder Kennung lesen; eine unbekannte Bestellung ist ein Fehler (zum Verzweigen: „Bestellungen suchen“). */
export const getOrderAction: ShopwareAction = {
  id: "getOrder",
  async execute({client, params, resolveText}) {
    const input = new ShopwareParams(params, resolveText);
    const reference = referenceFrom(input, {id: "orderId", number: "orderNumber"}, {id: "Bestell-ID", number: "Bestellnummer"});
    const order = mapShopwareOrder(await findOne(client, "order", reference, {numberField: "orderNumber", associations: orderAssociations, noun: "Die Bestellung"}));
    return {
      value: {type: "json", value: order},
      orderNumber: {type: "string", value: order.orderNumber},
      status: {type: "string", value: order.status},
      paymentStatus: {type: "string", value: order.paymentStatus},
      deliveryStatus: {type: "string", value: order.deliveryStatus},
      total: {type: "number", value: order.total},
      customerEmail: {type: "string", value: order.customer.email},
    };
  },
};
