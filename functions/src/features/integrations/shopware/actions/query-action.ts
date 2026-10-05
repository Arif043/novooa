import {type ShopwareAction} from "../domain/shopware-action.js";
import {ShopwareError} from "../domain/shopware-error.js";
import {ShopwareParams} from "../domain/shopware-params.js";

/** Kriterien, die der Baustein selbst setzt; sie stehen nicht im JSON, damit Seitenzahl und Limit eindeutig bleiben. */
const reservedCriteria = ["limit", "page", "total-count-mode"] as const;

/**
 * Experten-Abfrage: eine beliebige Entität mit eigenen Shopware-Kriterien (JSON) lesen. Nur lesend (`/search`); für
 * Schreibzugriffe gibt es eigene Aktionen oder den HTTP-Baustein.
 */
export const queryAction: ShopwareAction = {
  id: "query",
  async execute({client, params, resolveText}) {
    const input = new ShopwareParams(params, resolveText);
    const entity = input.text("entity", 100);
    if (entity === "") throw new ShopwareError("Bitte gib an, welche Entität abgefragt werden soll, z. B. „order“ oder „product“.");
    const criteria = input.jsonObject("criteria", "Kriterien");
    for (const key of reservedCriteria) {
      if (key in criteria) throw new ShopwareError(`„${key}“ steht nicht in den Kriterien; nutze dafür die Felder „Höchstanzahl“ und „Seite“.`);
    }
    const limit = input.integer("limit", "Höchstanzahl", {min: 1, max: 500, fallback: 50});
    const page = input.integer("page", "Seite", {min: 1, max: 100_000, fallback: 1});

    const result = await client.search(entity, {...criteria, limit, page});

    return {
      value: {type: "json", value: result.data},
      count: {type: "number", value: result.data.length},
      total: {type: "number", value: result.total},
      found: {type: "boolean", value: result.data.length > 0},
    };
  },
};
