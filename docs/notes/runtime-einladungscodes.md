# Einladungscodes der Runtime

> Neue Konten und zurückgesetzte Passwörter bekommen einen Einmalcode, mit dem die Person ihr Passwort selbst setzt; die Runtime braucht dafür keinen E-Mail-Versand.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- **Format:** 16 Zeichen Crockford-Base32 in Vierergruppen
  (`ABCD-EFGH-JKMN-PQRS`, 80 Bit). Beim Einlösen sind Bindestriche,
  Leerzeichen, Kleinschreibung sowie `O`/`I`/`L` statt `0`/`1` egal.
- **Speicherung:** nur der SHA-256-Hash in `runtime_invitations`; wie bei
  Sitzungstokens genügt bei so viel Zufall ein schneller Hash. Die App zeigt den
  Code deshalb genau einmal (mit Kopieren-Knopf).
- **Gültigkeit:** 72 Stunden, genau einmal einlösbar; ein neuer Code ersetzt
  den offenen Code desselben Kontos.
- **Einlösen:** `POST /v1/auth/invitations/redeem {code, password}` setzt das
  Passwort und liefert gleich ein Session-Token. App: Anmeldung → „Ich habe
  einen Einladungscode“.
- **Zurücksetzen** (`POST /v1/users/:uid/invitation`) löscht zuerst das alte
  Passwort und alle Sitzungen des Kontos.
- **Notzugang:** Kommt kein Admin mehr hinein, setzt
  `POST /v1/auth/recover {activationToken, loginName, password}` das Passwort
  eines Admins neu — Nachweis ist wie bei der
  [Ersteinrichtung](./runtime-ersteinrichtung.md) der Lizenz-Token. App:
  Anmeldung → „Admin-Zugang wiederherstellen“.
- Einlösen und Notzugang zählen zur [Login-Ratenbegrenzung](./login-ratenbegrenzung.md).

## Siehe auch

- [Benutzerkonten der Runtime](./runtime-benutzerkonten.md)
