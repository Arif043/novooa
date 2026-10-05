/** Prüft, ob die Prüfsumme eines Pakets vom Plugin-Herausgeber (Admin) signiert wurde. */
export interface PluginSignatureVerifier {
  verify(digest: Uint8Array, signature: Uint8Array | undefined): boolean;
}
