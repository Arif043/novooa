import {type ShopwareProduct} from "../domain/shopware-product.js";
import {first, label, number, text, type Raw} from "./shopware-record.js";

/** Assoziationen, die das Modell braucht. */
export const productAssociations = {manufacturer: {}, tax: {}};

export function mapShopwareProduct(raw: Raw): ShopwareProduct {
  const price = first(raw.price);
  return {
    id: text(raw.id),
    productNumber: text(raw.productNumber),
    name: label(raw),
    active: raw.active === true,
    stock: number(raw.stock),
    availableStock: number(raw.availableStock),
    price: Object.keys(price).length === 0 ? null : {gross: number(price.gross), net: number(price.net)},
    ean: text(raw.ean),
    manufacturer: label(raw.manufacturer),
    parentId: text(raw.parentId),
    raw,
  };
}
