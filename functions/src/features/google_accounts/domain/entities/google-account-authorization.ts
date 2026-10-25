/** Eine begonnene Anmeldung; sie gilt kurz und wird beim Callback genau einmal verbraucht. */
export type GoogleAccountAuthorization = {
  id: string;
  teamId: string;
  runtimeLicenseId: string;
  codeVerifier: string;
  expiresAt: Date;
};
