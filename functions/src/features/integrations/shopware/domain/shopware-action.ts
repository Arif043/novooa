import {type NodeOutputValue} from "../../../task_execution/domain/entities/task.js";
import {type ShopwareClient} from "../infrastructure/shopware-client.js";

export type ShopwareActionContext = {
  client: ShopwareClient;
  /** Die Eingaben des Bausteins, noch nicht geprüft und mit unaufgelösten Templates. */
  params: Record<string, unknown>;
  /** Setzt `{{…}}`-Ausdrücke aus vorherigen Bausteinen ein. */
  resolveText: (template: string) => string;
  /** Das Ereignis, das den Lauf gestartet hat (`input.event`), falls es eines gab. */
  event?: unknown;
};

/** Eine Aktion des Shopware-Bausteins (z. B. „Bestellungen suchen“). Sie prüft ihre `params` selbst. */
export type ShopwareAction = {
  id: string;
  /** `false`: die Aktion arbeitet nur mit dem Ereignis des Laufs und braucht keine Verbindung (Standard: `true`). */
  usesConnection?: boolean;
  execute(context: ShopwareActionContext): Promise<Record<string, NodeOutputValue>>;
  /**
   * Nur ändernde Aktionen: ein neutrales Kennzeichen der Folge (z. B. die Bestellnummer) aus den
   * Ausgaben; `undefined`, wenn sich nichts geändert hat. Den Satz bildet der Client.
   */
  effectLabel?(outputs: Record<string, NodeOutputValue>): string | undefined;
};

export class ShopwareActionRegistry {
  private readonly actions = new Map<string, ShopwareAction>();

  register(action: ShopwareAction): this {
    this.actions.set(action.id, action);
    return this;
  }

  find(id: string): ShopwareAction | undefined {
    return this.actions.get(id);
  }

  ids(): string[] {
    return [...this.actions.keys()];
  }
}
