import {type NodeOutputValue} from "../../../task_execution/domain/entities/task.js";
import {type ShopwareAction} from "../domain/shopware-action.js";
import {ShopwareError} from "../domain/shopware-error.js";
import {isRecord, text} from "../infrastructure/shopware-record.js";
import {shopwareTriggerEvents} from "../triggers/shopware-trigger-params.js";

/** Macht das Ereignis eines Shopware-Auslösers nutzbar: den Datensatz im einfachen Modell und die Art des Ereignisses. */
export const readEventAction: ShopwareAction = {
  id: "readEvent",
  usesConnection: false,
  async execute({event}) {
    if (!isRecord(event) || event.type !== "shopwareEvent") {
      throw new ShopwareError("Dieser Lauf wurde nicht durch ein Shopware-Ereignis gestartet.");
    }
    const kind = text(event.kind);
    if (!shopwareTriggerEvents.some((known) => known === kind)) throw new ShopwareError("Das Shopware-Ereignis ist unbekannt.");
    const outputs: Record<string, NodeOutputValue> = {
      value: {type: "json", value: event.value ?? null},
      event: {type: "string", value: kind},
      id: {type: "string", value: text(event.id)},
      receivedAt: {type: "datetime", value: text(event.receivedAt)},
    };
    return outputs;
  },
};
