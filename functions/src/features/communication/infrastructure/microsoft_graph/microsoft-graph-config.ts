import {defineSecret, defineString} from "firebase-functions/params";
import {AccessTokenCache} from "../../domain/services/access-token-cache.js";
import {MailConnectorTokenService} from "../../domain/services/mail-connector-token-service.js";
import {type MailConnectorRepository} from "../../domain/repositories/mail-connector-repository.js";
import {type MailProvider} from "../../domain/repositories/mail-provider.js";
import {CredentialCipher} from "../../../../shared/security/credential-cipher.js";
import {MicrosoftGraphProvider} from "./microsoft-graph-provider.js";

export const microsoftGraphClientId = defineString("MICROSOFT_GRAPH_CLIENT_ID");
export const microsoftGraphRedirectUri = defineString("MICROSOFT_GRAPH_REDIRECT_URI");
export const microsoftGraphWebhookUrl = defineString("MICROSOFT_GRAPH_WEBHOOK_URL");
export const microsoftGraphClientSecret = defineSecret("MICROSOFT_GRAPH_CLIENT_SECRET");
export const mailConnectorEncryptionKey = defineSecret("MAIL_CONNECTOR_ENCRYPTION_KEY");

export function microsoftGraphAuthorizationProvider(): MicrosoftGraphProvider {
  return providerFrom("");
}

export function microsoftGraphProvider(): MicrosoftGraphProvider {
  return providerFrom(microsoftGraphClientSecret.value());
}

/** Pro Funktionsinstanz geteilt: Aufeinanderfolgende Aufrufe auf einer warmen Instanz holen kein neues Zugriffstoken. */
const mailAccessTokenCache = new AccessTokenCache();

export function mailTokenService(
  repository: MailConnectorRepository,
  provider: MailProvider = microsoftGraphProvider(),
): MailConnectorTokenService {
  return new MailConnectorTokenService(repository, provider, mailAccessTokenCache);
}

export function mailConnectorCipher(): CredentialCipher {
  return new CredentialCipher(mailConnectorEncryptionKey.value());
}

function providerFrom(clientSecret: string): MicrosoftGraphProvider {
  return new MicrosoftGraphProvider({
    clientId: requiredValue(microsoftGraphClientId.value(), "MICROSOFT_GRAPH_CLIENT_ID"),
    clientSecret,
    redirectUri: requiredValue(microsoftGraphRedirectUri.value(), "MICROSOFT_GRAPH_REDIRECT_URI"),
    notificationUrl: requiredValue(microsoftGraphWebhookUrl.value(), "MICROSOFT_GRAPH_WEBHOOK_URL"),
  });
}

function requiredValue(value: string, name: string): string {
  const trimmed = value.trim();
  if (!trimmed) throw new Error(`${name} is required.`);
  return trimmed;
}
