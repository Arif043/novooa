import {FieldValue} from "firebase-admin/firestore";
import {getDatabase} from "../../../../shared/firebase/firestore-db.js";
import {hasFlag, optionalArgument, reportFailure, requiredMaxUsers} from "./license-cli-arguments.js";

void setMaxUsers().catch(reportFailure);

/**
 * Setzt die Nutzerstaffel (`maxUsers`) an ausgestellten Lizenzen: einer (`--license-id`) oder allen (`--all`).
 * Die Runtime bekommt den neuen Wert mit der nächsten signierten Lizenz (Aktivierung oder Erneuerung).
 */
async function setMaxUsers(): Promise<void> {
  const licenseId = optionalArgument("license-id");
  if ((licenseId === undefined) === !hasFlag("all")) throw new Error("Entweder --license-id oder --all angeben.");
  const maxUsers = requiredMaxUsers();
  const licenses = getDatabase().collection("licenses");
  const snapshot = licenseId === undefined ? await licenses.get() : await licenses.where("licenseId", "==", licenseId).get();
  if (snapshot.empty) throw new Error("Keine passende Lizenz gefunden.");
  for (const document of snapshot.docs) {
    await document.ref.update({maxUsers, updatedAt: FieldValue.serverTimestamp()});
    console.log(`${String(document.get("licenseId"))} (${String(document.get("name"))}): maxUsers = ${maxUsers ?? "unbegrenzt"}`);
  }
}
