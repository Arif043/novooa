# Team-Kontext und Einladungen

> Jede angemeldete Person bekommt automatisch ein Team mit generierter ID; der aktuelle Team-Kontext steht in `users/{uid}.teamId`.

Gehört zu: [Architektur](../index/architektur.md)

```text
users/{uid}.teamId = "{teamId}"
teams/{teamId}
teams/{teamId}/members/{uid}
```

- Die Team-ID wird nicht aus der UID abgeleitet. Client und Functions lösen
  den Kontext über `users/{uid}.teamId` auf; Aufgaben, Dateien, Aktivitäten
  und Storage-Pfade bleiben team-scoped.
- Auch wenn heute nur ein persönlicher Arbeitsbereich genutzt wird, ist alles
  von Beginn an team-scoped modelliert.
- Einladungen sind Notifications unter `users/{uid}/notifications/{id}`;
  Annehmen setzt `users/{uid}.teamId` und legt `teams/{teamId}/members/{uid}`
  an.
- Standalone: Ein Team entspricht einem Arbeitsbereich, abgeleitet aus der
  signierten Lizenz ([Benutzerprofile und Teammitglieder](./sqlite-teammitglieder-normalisiert.md)).

## Siehe auch

- [Benachrichtigungen und Push](./benachrichtigungen-und-push.md)
- [Firestore im Client](./firestore-client-persistenz.md)
