export type IssuedInvitation = {code: string; expiresAt: string};

/** Einmalcodes, mit denen eine Person ihr Passwort selbst setzt (Einladung oder Zurücksetzen). */
export interface InvitationRepository {
  /** Ersetzt einen offenen Code desselben Kontos. */
  issue(uid: string): Promise<IssuedInvitation>;
  /** Löst den Code ein und liefert das Konto; abgelaufen oder unbekannt → `null`. */
  redeem(code: string): Promise<string | null>;
}
