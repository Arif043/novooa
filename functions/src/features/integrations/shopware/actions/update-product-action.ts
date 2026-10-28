import {changed, jsonField} from "../../external-action-effect.js";
import {type ShopwareAction} from "../domain/shopware-action.js";
import {ShopwareError} from "../domain/shopware-error.js";
import {ShopwareParams} from "../domain/shopware-params.js";
import {type ShopwareProduct} from "../domain/shopware-product.js";
import {type ShopwareClient} from "../infrastructure/shopware-client.js";
import {findOne, referenceFrom} from "../infrastructure/shopware-lookup.js";
import {mapShopwareProduct, productAssociations} from "../infrastructure/shopware-product-mapper.js";
import {list, number, record, text, type Raw} from "../infrastructure/shopware-record.js";

export const productActiveChanges = ["true", "false"] as const;

/** Die Standardwährung jedes Shops (`Defaults::CURRENCY`); sie trägt den Preis, wenn das Produkt noch keinen hat. */
const defaultCurrencyId = "b7d2554b0ce847cd82f3ac9bd1c0dfca";

/**
 * Produkt ändern: Bestand, Preis (brutto) und Aktiv. Geändert wird nur, was eingetragen ist. Beim Preis berechnet die
 * Aktion den Nettopreis aus dem Steuersatz des Produkts; Preise anderer Währungen bleiben erhalten.
 */
export const updateProductAction: ShopwareAction = {
  id: "updateProduct",
  async execute({client, params, resolveText}) {
    const input = new ShopwareParams(params, resolveText);
    const reference = referenceFrom(input, {id: "productId", number: "productNumber"}, {id: "Produkt-ID", number: "Artikelnummer"});
    const stock = input.optionalInteger("stock", "Bestand", {min: 0, max: 1_000_000_000});
    const gross = input.optionalDecimal("price", "Preis brutto", {min: 0, max: 1_000_000_000});
    const active = input.choice("active", productActiveChanges, "Aktiv");
    if (stock === undefined && gross === undefined && active === "") {
      throw new ShopwareError("Bitte gib an, was am Produkt geändert werden soll: Bestand, Preis oder Aktiv.");
    }

    const raw = await findOne(client, "product", reference, {numberField: "productNumber", associations: productAssociations, noun: "Das Produkt"});
    const before = mapShopwareProduct(raw);
    const body: Record<string, unknown> = {};
    if (stock !== undefined) body.stock = stock;
    if (active !== "") body.active = active === "true";
    if (gross !== undefined) body.price = await priceEntries(client, raw, gross);

    await client.request("PATCH", `/api/product/${before.id}`, body);

    const after = mapShopwareProduct(await findOne(client, "product", {id: before.id}, {numberField: "productNumber", associations: productAssociations, noun: "Das Produkt"}));
    return {
      value: {type: "json", value: after},
      changed: {type: "boolean", value: differs(before, after)},
    };
  },
  effectLabel: (outputs) => changed(outputs) ? jsonField(outputs.value, "productNumber") : undefined,
};

function differs(before: ShopwareProduct, after: ShopwareProduct): boolean {
  return before.stock !== after.stock || before.active !== after.active || before.price?.gross !== after.price?.gross;
}

/** Der neue Preis in der Währung des bisherigen Preises (sonst Standardwährung); Preise anderer Währungen bleiben. */
async function priceEntries(client: ShopwareClient, raw: Raw, gross: number): Promise<unknown[]> {
  const existing = list(raw.price);
  const currencyId = text(existing[0]?.currencyId) || defaultCurrencyId;
  const rate = await taxRateOf(client, raw);
  const net = Math.round((gross / (1 + rate / 100)) * 1_000_000) / 1_000_000;
  const others = existing.filter((entry) => text(entry.currencyId) !== currencyId);
  return [...others, {currencyId, gross, net, linked: true}];
}

/** Varianten erben den Steuersatz oft vom Hauptprodukt. */
async function taxRateOf(client: ShopwareClient, raw: Raw): Promise<number> {
  const own = record(raw.tax).taxRate;
  if (typeof own === "number") return number(own);
  const parentId = text(raw.parentId);
  if (parentId !== "") {
    const parent = await findOne(client, "product", {id: parentId}, {numberField: "productNumber", associations: productAssociations, noun: "Das Hauptprodukt"});
    const inherited = record(parent.tax).taxRate;
    if (typeof inherited === "number") return inherited;
  }
  throw new ShopwareError("Der Steuersatz des Produkts konnte nicht bestimmt werden; der Preis wird deshalb nicht geändert.");
}
