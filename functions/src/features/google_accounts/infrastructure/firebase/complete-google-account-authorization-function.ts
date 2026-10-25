import {onRequest} from "firebase-functions/v2/https";
import {type Request} from "express";
import {completeGoogleAccountAuthorization} from "../../domain/usecases/complete-google-account-authorization.js";
import {logException, logInfo} from "../../../../shared/logging/logger.js";
import {sendOAuthResultPage} from "../../../../shared/firebase/oauth-result-page.js";
import {authorizationId} from "../../../../shared/security/oauth-pkce.js";
import {
  googleAccountCipher,
  googleAccountEncryptionKey,
  googleOAuthClientSecret,
  googleOAuthProvider,
} from "../google/google-account-config.js";
import {FirestoreGoogleAccountRepository} from "./firestore-google-account-repository.js";

/** Rückkehr von Google nach Login und Picker; die Weiterleitungs-URI des OAuth-Clients zeigt hierher. */
export const completeGoogleAccountAuthorizationFunction = onRequest(
  {invoker: "public", secrets: [googleOAuthClientSecret, googleAccountEncryptionKey]},
  async (request, response) => {
    if (request.method !== "GET") return void response.status(405).send("Method Not Allowed");
    if (typeof request.query.error === "string") return void failed(response, "Die Anmeldung wurde abgebrochen.");
    try {
      const account = await complete(request);
      logInfo("google_account.connected", {teamId: account.teamId, accountId: account.id, sharedItems: account.sharedItems.length});
      sendOAuthResultPage(response, {
        ok: true, title: "Google-Konto verbunden",
        message: `${account.email} ist jetzt mit novooa verbunden. Du kannst dieses Fenster schließen.`,
      });
    } catch (error) {
      logException("google_account.authorization_failed", error);
      failed(response, "Das Google-Konto konnte nicht verbunden werden.");
    }
  },
);

function complete(request: Request) {
  return completeGoogleAccountAuthorization({
    authorizationId: requiredQuery(request, "state"),
    authorizationCode: requiredQuery(request, "code"),
    pickedItemIds: pickedItemIdsFrom(request.query.picked_file_ids),
    newAccountId: authorizationId(),
    repository: new FirestoreGoogleAccountRepository(googleAccountCipher()),
    provider: googleOAuthProvider(),
    now: new Date(),
  });
}

/** Der Picker liefert kommagetrennte IDs; mehr als 100 auf einmal sind kein sinnvoller Fall. */
function pickedItemIdsFrom(value: unknown): string[] {
  if (typeof value !== "string") return [];
  return value.split(",").map((id) => id.trim()).filter((id) => /^[\w-]{1,200}$/.test(id)).slice(0, 100);
}

function requiredQuery(request: Request, name: string): string {
  const value = request.query[name];
  if (typeof value !== "string" || value.length === 0) throw new Error(`OAuth-Parameter ${name} fehlt.`);
  return value;
}

function failed(response: Parameters<typeof sendOAuthResultPage>[0], message: string): void {
  sendOAuthResultPage(response, {ok: false, title: "Verbindung fehlgeschlagen", message});
}
