import {type ShopwareAction} from "../domain/shopware-action.js";
import {ShopwareParams} from "../domain/shopware-params.js";
import {mapShopwareProduct, productAssociations} from "../infrastructure/shopware-product-mapper.js";

export const productActiveFilters = ["true", "false"] as const;
export const productSortings = ["name", "newest", "stock"] as const;

const sortings = {
  name: {field: "name", order: "ASC"},
  newest: {field: "createdAt", order: "DESC"},
  stock: {field: "stock", order: "ASC"},
} as const;

/** Produkte suchen: Name, Artikelnummer, aktiv, Bestand; liefert die Liste im einfachen Modell. */
export const searchProductsAction: ShopwareAction = {
  id: "searchProducts",
  async execute({client, params, resolveText}) {
    const input = new ShopwareParams(params, resolveText);
    const filter: Array<Record<string, unknown>> = [];
    const name = input.text("name", 200);
    if (name !== "") filter.push({type: "contains", field: "name", value: name});
    const number = input.text("productNumber", 64);
    if (number !== "") filter.push({type: "equals", field: "productNumber", value: number});
    const active = input.choice("active", productActiveFilters, "Aktiv");
    if (active !== "") filter.push({type: "equals", field: "active", value: active === "true"});
    const stockMin = input.optionalInteger("stockMin", "Bestand ab", {min: -1_000_000, max: 1_000_000_000});
    const stockMax = input.optionalInteger("stockMax", "Bestand bis", {min: -1_000_000, max: 1_000_000_000});
    if (stockMin !== undefined || stockMax !== undefined) {
      filter.push({type: "range", field: "stock", parameters: {...(stockMin === undefined ? {} : {gte: stockMin}), ...(stockMax === undefined ? {} : {lte: stockMax})}});
    }
    const sorting = input.choice("sort", productSortings, "Reihenfolge") || "name";
    const limit = input.integer("limit", "Höchstanzahl", {min: 1, max: 500, fallback: 50});

    const result = await client.searchAll("product", {filter, sort: [sortings[sorting]], associations: productAssociations}, limit);

    const products = result.data.map(mapShopwareProduct);
    return {
      value: {type: "json", value: products},
      count: {type: "number", value: products.length},
      total: {type: "number", value: result.total},
      found: {type: "boolean", value: products.length > 0},
    };
  },
};
