import {type ShopwareCustomer} from "../domain/shopware-customer.js";
import {label, record, text, type Raw} from "./shopware-record.js";

export const customerAssociations = {group: {}, defaultBillingAddress: {associations: {country: {}}}};

export function mapShopwareCustomer(raw: Raw): ShopwareCustomer {
  const address = record(raw.defaultBillingAddress);
  return {
    id: text(raw.id),
    customerNumber: text(raw.customerNumber),
    email: text(raw.email),
    firstName: text(raw.firstName),
    lastName: text(raw.lastName),
    company: text(raw.company),
    active: raw.active === true,
    guest: raw.guest === true,
    group: label(raw.group),
    createdAt: text(raw.createdAt),
    billingAddress: Object.keys(address).length === 0
      ? null
      : {street: text(address.street), zip: text(address.zipcode), city: text(address.city), country: label(address.country)},
    raw,
  };
}
