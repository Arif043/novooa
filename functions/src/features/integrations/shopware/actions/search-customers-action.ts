import {type ShopwareAction} from "../domain/shopware-action.js";
import {ShopwareParams} from "../domain/shopware-params.js";
import {customerAssociations, mapShopwareCustomer} from "../infrastructure/shopware-customer-mapper.js";

export const customerActiveFilters = ["true", "false"] as const;
export const customerSortings = ["newest", "name"] as const;

const sortings = {
  newest: [{field: "createdAt", order: "DESC"}],
  name: [{field: "lastName", order: "ASC"}, {field: "firstName", order: "ASC"}],
} as const;

/** Kunden suchen: E-Mail, Name, Kundennummer, aktiv; liefert die Liste im einfachen Modell. */
export const searchCustomersAction: ShopwareAction = {
  id: "searchCustomers",
  async execute({client, params, resolveText}) {
    const input = new ShopwareParams(params, resolveText);
    const filter: Array<Record<string, unknown>> = [];
    const email = input.text("email", 254);
    if (email !== "") filter.push({type: "contains", field: "email", value: email});
    const name = input.text("name", 200);
    if (name !== "") {
      filter.push({
        type: "multi", operator: "OR",
        queries: ["firstName", "lastName", "company"].map((field) => ({type: "contains", field, value: name})),
      });
    }
    const number = input.text("customerNumber", 64);
    if (number !== "") filter.push({type: "equals", field: "customerNumber", value: number});
    const active = input.choice("active", customerActiveFilters, "Aktiv");
    if (active !== "") filter.push({type: "equals", field: "active", value: active === "true"});
    const sorting = input.choice("sort", customerSortings, "Reihenfolge") || "newest";
    const limit = input.integer("limit", "Höchstanzahl", {min: 1, max: 500, fallback: 50});

    const result = await client.searchAll("customer", {filter, sort: sortings[sorting], associations: customerAssociations}, limit);

    const customers = result.data.map(mapShopwareCustomer);
    return {
      value: {type: "json", value: customers},
      count: {type: "number", value: customers.length},
      total: {type: "number", value: result.total},
      found: {type: "boolean", value: customers.length > 0},
    };
  },
};
