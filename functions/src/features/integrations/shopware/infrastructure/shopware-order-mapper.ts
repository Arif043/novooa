import {type ShopwareAddress, type ShopwareOrder, type ShopwareOrderLineItem} from "../domain/shopware-order.js";

type Raw = Record<string, unknown>;

/** Die Assoziationen, die die Suche für das Modell braucht (Shopware lädt sie nicht von selbst). */
export const orderAssociations = {
  lineItems: {sort: [{field: "position", order: "ASC"}]},
  orderCustomer: {},
  currency: {},
  stateMachineState: {},
  billingAddress: {associations: {country: {}}},
  transactions: {associations: {stateMachineState: {}, paymentMethod: {}}, sort: [{field: "createdAt", order: "DESC"}]},
  deliveries: {associations: {stateMachineState: {}, shippingMethod: {}, shippingOrderAddress: {associations: {country: {}}}}},
};

export function mapShopwareOrder(raw: Raw): ShopwareOrder {
  const transaction = first(raw.transactions);
  const delivery = first(raw.deliveries);
  const customer = record(raw.orderCustomer);
  return {
    id: text(raw.id),
    orderNumber: text(raw.orderNumber),
    createdAt: text(raw.createdAt),
    status: text(record(raw.stateMachineState).technicalName),
    statusLabel: label(raw.stateMachineState),
    paymentStatus: text(record(transaction.stateMachineState).technicalName),
    paymentStatusLabel: label(transaction.stateMachineState),
    deliveryStatus: text(record(delivery.stateMachineState).technicalName),
    deliveryStatusLabel: label(delivery.stateMachineState),
    currency: text(record(raw.currency).isoCode),
    total: number(raw.amountTotal),
    netTotal: number(raw.amountNet),
    customer: {
      id: text(customer.customerId), number: text(customer.customerNumber), email: text(customer.email),
      firstName: text(customer.firstName), lastName: text(customer.lastName), company: text(customer.company),
    },
    billingAddress: address(raw.billingAddress),
    shippingAddress: address(delivery.shippingOrderAddress),
    shippingMethod: label(delivery.shippingMethod),
    paymentMethod: label(transaction.paymentMethod),
    customerComment: text(raw.customerComment),
    lineItems: list(raw.lineItems).map(lineItem).sort((a, b) => a.position - b.position).map(({position: _position, ...item}) => item),
    raw,
  };
}

function lineItem(raw: Raw): ShopwareOrderLineItem & {position: number} {
  return {
    id: text(raw.id), label: text(raw.label), productNumber: text(record(raw.payload).productNumber),
    quantity: number(raw.quantity), unitPrice: number(raw.unitPrice), total: number(raw.totalPrice), type: text(raw.type),
    position: number(raw.position),
  };
}

function address(value: unknown): ShopwareAddress | null {
  const raw = record(value);
  if (Object.keys(raw).length === 0) return null;
  return {
    firstName: text(raw.firstName), lastName: text(raw.lastName), company: text(raw.company),
    street: text(raw.street), zip: text(raw.zipcode), city: text(raw.city), country: label(raw.country),
  };
}

/** Der Anzeigename in der Sprache des Shops (`translated.name`), sonst `name`. */
function label(value: unknown): string {
  const raw = record(value);
  return text(record(raw.translated).name) || text(raw.name);
}

function first(value: unknown): Raw {
  return list(value)[0] ?? {};
}

function list(value: unknown): Raw[] {
  return Array.isArray(value) ? value.filter(isRecord) : [];
}

function record(value: unknown): Raw {
  return isRecord(value) ? value : {};
}

function isRecord(value: unknown): value is Raw {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function text(value: unknown): string {
  return typeof value === "string" ? value : typeof value === "number" ? String(value) : "";
}

function number(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}
