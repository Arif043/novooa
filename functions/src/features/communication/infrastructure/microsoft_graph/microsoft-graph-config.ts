import {defineSecret, defineString} from "firebase-functions/params";
import {CredentialCipher} from "../security/credential-cipher.js";
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
