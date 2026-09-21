import {HttpsError, onCall} from "firebase-functions/v2/https";
import {currentTeamIdForUid} from
  "../../../teams/infrastructure/firebase/firebase-team-context.js";
import {beginMailConnectorAuthorization} from
  "../../domain/usecases/begin-mail-connector-authorization.js";
import {FirestoreMailConnectorRepository} from
  "../firebase/firestore-mail-connector-repository.js";
import {
  mailConnectorCipher,
  mailConnectorEncryptionKey,
  microsoftGraphAuthorizationProvider,
} from "../microsoft_graph/microsoft-graph-config.js";
import {
  authorizationCodeVerifier,
  authorizationId,
  codeChallenge,
} from "../microsoft_graph/microsoft-oauth-proof.js";

export const beginMicrosoftMailConnector = onCall(
  {secrets: [mailConnectorEncryptionKey]},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Anmeldung erforderlich.");
    return beginAuthorization(uid);
  },
);

async function beginAuthorization(uid: string): Promise<{authorizationUrl: string}> {
  const verifier = authorizationCodeVerifier();
  const teamId = await currentTeamIdForUid(uid);
  return beginMailConnectorAuthorization({
    authorization: {
      id: authorizationId(), teamId, uid, provider: "microsoftGraph", codeVerifier: verifier,
      deliveryTarget: "cloud", runtimeLicenseId: null,
      expiresAt: expiresAt(),
    },
    codeChallenge: codeChallenge(verifier),
    repository: new FirestoreMailConnectorRepository(mailConnectorCipher()),
    provider: microsoftGraphAuthorizationProvider(),
  });
}

function expiresAt(): Date {
  return new Date(Date.now() + 10 * 60 * 1000);
}
