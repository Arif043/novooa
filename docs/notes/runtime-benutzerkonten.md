# Benutzerkonten der Runtime

> Eine Standalone-Runtime hat mehrere Konten mit Anmeldename und Passwort; alle sehen den ganzen Arbeitsbereich, Admins verwalten zusätzlich Benutzer, Lizenz und Anbindungen.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- **Code:** `functions/src/features/runtime_users/` (Domain: Use Cases in
  `runtime-access.ts` und `runtime-user-management.ts`), App:
  `lib/features/runtime_users/`.
- **Konto** = `user_profiles` mit `login_name` (eindeutig, klein geschrieben,
  3–64 Zeichen aus `a–z 0–9 . _ -`) plus Mitgliedschaft in `team_members` des
  aktiven Arbeitsbereichs. Das Passwort liegt getrennt in
  `runtime_password_credentials` (scrypt, wie bisher), damit ein Konto später
  auch ohne Passwort bestehen kann ([SSO, geplant](./runtime-sso-geplant.md)).
- **Erstes Konto:** die [Ersteinrichtung](./runtime-ersteinrichtung.md) macht
  das Profil des Arbeitsbereichs (`license-<licenseId>`) zum ersten Admin; so
  passen `created_by_uid` vorhandener Daten. Dieses Konto lässt sich nicht
  löschen.
- **Weitere Konten** legt ein Admin an; die Person setzt ihr Passwort mit einem
  [Einladungscode](./runtime-einladungscodes.md). Die Lizenz begrenzt die Zahl
  der Konten (`maxUsers`, `409 user_limit_reached`).
- **Sichtbarkeit:** Alle Konten arbeiten im selben Team und sehen alles.

## Rollen

| Bereich | Mitglied | Admin |
| --- | --- | --- |
| Aufgaben, Läufe, Freigaben, Formulare, Auslöser, Wissensbasis, Dateien, Daten, Mitarbeiter, ML-Modelle | ja | ja |
| Verbindungen, Sprachmodelle, Mail-Connectoren, Script-Pakete, Skills, Dateieinstellungen | nur lesen | ja |
| Benutzer, Import/Export, Protokoll lesen, Lizenz freigeben | nein | ja |

- Durchgesetzt im Backend (`local-runtime-role-policy.ts`, Hook in
  `local-runtime-access-hooks.ts` → `403 {code: "admin_required"}`); die Rolle
  wird bei jeder Anfrage gelesen, eine Änderung wirkt sofort.
- Es bleibt immer mindestens ein Admin (`409 last_admin`); das eigene Konto
  lässt sich nicht löschen oder zurücksetzen (`409 own_account`).
- Löschen und Zurücksetzen beenden alle Sitzungen des Kontos samt offener
  Realtime-Verbindungen sofort. Inhalte bleiben im Arbeitsbereich.
- Die App blendet Admin-Bereiche für Mitglieder aus: Einstellungen zeigen nur
  „Allgemein“ (Sprache, Geräte, eigenes Passwort) und „Machine Learning“, die
  Aktivitäten kein „Protokoll“.

## Schnittstelle

- `GET /v1/auth/me` → `{uid, loginName, displayName, role, hasPassword, createdAt}`
- `GET /v1/users` → `{items, maxUsers}`; `POST /v1/users {loginName, displayName, role}`
  → `{user, invitation}`; `PUT /v1/users/:uid {displayName?, role?}`;
  `POST /v1/users/:uid/invitation` (Passwort zurücksetzen, neuer Code);
  `DELETE /v1/users/:uid`. Änderungen melden das Realtime-Thema `users`.
- App: Einstellungen → **Benutzer** (nur Admins): Belegung „n von m“, Liste mit
  Initialen, „Benutzer hinzufügen“ und Menü je Konto.

## Siehe auch

- [Anmeldepflicht der Runtime](./runtime-anmeldepflicht.md)
- [Herkunft eines Laufs](./lauf-herkunft.md)
- [Lokales Lizenzmodell](./lokales-lizenzmodell.md)
