import {MailReauthorizationRequiredError} from "../services/mail-connector-token-service.js";
import {
  recreateMailConnectorSubscription,
  renewMailConnectorSubscription,
  type SubscriptionInput,
} from "./renew-mail-connector-subscription.js";

export type LifecycleOutcome = "renewed" | "recreated" | "reauthorizationRequired" | "ignored";

/**
 * Reagiert auf Lifecycle-Benachrichtigungen des Anbieters:
 *
 * - `reauthorizationRequired`: Die Subscription braucht eine Bestätigung mit gültigem
 *   Token — das Verlängern leistet genau das.
 * - `subscriptionRemoved`: Der Anbieter hat die Subscription entfernt; eine neue wird angelegt.
 * - alles andere (`missed`, unbekannt): keine Aktion.
 *
 * Ist die Anmeldung des Nutzers ungültig, steht der Connector danach auf
 * `reauthorizationRequired`; das Ergebnis meldet es, ohne zu werfen, damit die
 * Aufgabenwarteschlange einen aussichtslosen Versuch nicht wiederholt.
 */
export async function handleMailSubscriptionLifecycle(
  input: SubscriptionInput & {event: string},
): Promise<LifecycleOutcome> {
  try {
    if (input.event === "reauthorizationRequired") return await renewMailConnectorSubscription(input);
    if (input.event === "subscriptionRemoved") return await recreateMailConnectorSubscription(input);
    return "ignored";
  } catch (error) {
    if (error instanceof MailReauthorizationRequiredError) return "reauthorizationRequired";
    throw error;
  }
}
