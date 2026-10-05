import {ShopwareError} from "../domain/shopware-error.js";
import {type ShopwareParams} from "../domain/shopware-params.js";
import {type ShopwareClient, type ShopwareRecord} from "./shopware-client.js";

const idPattern = /^[0-9a-f]{32}$/i;

/** Ein Datensatz, benannt über seine Kennung (32 Zeichen) oder seine Nummer. */
export type RecordReference = {id: string} | {number: string};

/**
 * Liest „Nummer oder ID“ aus den Eingaben. Die Kennung hat Vorrang; fehlen beide, bekommt der Nutzer die Namen der
 * Felder genannt.
 */
export function referenceFrom(
  input: ShopwareParams,
  keys: {id: string; number: string},
  labels: {id: string; number: string},
): RecordReference {
  const id = input.text(keys.id, 64);
  if (id !== "") {
    if (!idPattern.test(id)) throw new ShopwareError(`„${labels.id}“ muss aus 32 Zeichen (0–9, a–f) bestehen.`);
    return {id: id.toLowerCase()};
  }
  const number = input.text(keys.number, 64);
  if (number === "") throw new ShopwareError(`Bitte gib „${labels.number}“ oder „${labels.id}“ an.`);
  return {number};
}

/** Genau ein Datensatz; kein Treffer ist ein Fehler mit verständlicher Meldung. */
export async function findOne(
  client: ShopwareClient,
  entity: string,
  reference: RecordReference,
  options: {numberField: string; associations: ShopwareRecord; noun: string},
): Promise<ShopwareRecord> {
  const criteria: ShopwareRecord = {associations: options.associations, limit: 1};
  if ("id" in reference) criteria.ids = [reference.id];
  else criteria.filter = [{type: "equals", field: options.numberField, value: reference.number}];
  const {data} = await client.search(entity, criteria);
  const found = data[0];
  if (found === undefined) {
    const named = "id" in reference ? `mit der Kennung ${reference.id}` : `mit der Nummer ${reference.number}`;
    throw new ShopwareError(`${options.noun} ${named} wurde in Shopware nicht gefunden.`);
  }
  return found;
}
