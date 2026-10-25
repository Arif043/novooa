# Cloud-Endpunkte der Runtime

> Die Runtime erreicht die Firebase-Hintergrunddienste nur über konfigurierte Relay- und Gateway-URLs; der Produktiv-Container braucht diese Variablen.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

```text
LOCAL_RUNTIME_LICENSE_GATEWAY_URL=https://<region>-<projekt>.cloudfunctions.net/issueLocalRuntimeLicense
LOCAL_RUNTIME_PUSH_RELAY_URL=https://<region>-<projekt>.cloudfunctions.net/localRuntimePushRelay
LOCAL_RUNTIME_MAIL_RELAY_URL=https://<region>-<projekt>.cloudfunctions.net/localRuntimeMailRelay
LOCAL_RUNTIME_FIREBASE_API_KEY=<Firebase-Web-API-Key>
LOCAL_RUNTIME_FIREBASE_PROJECT_ID=<Firebase-Projekt-ID>
LOCAL_RUNTIME_FIREBASE_TOKEN_URL=https://<region>-<projekt>.cloudfunctions.net/issueLocalRuntimeFirebaseToken
```

Weitere Relays:

- `LOCAL_RUNTIME_GOOGLE_RELAY_URL` → `localRuntimeGoogleRelay`, in Compose
  voreingestellt ([Google-Konto verbinden](./google-konto-verbinden.md))
- `LOCAL_RUNTIME_TASK_BUILDER_RELAY_URL` → `localRuntimeTaskBuilderRelay`
  ([KI-Agenten in der Runtime](./ki-agenten-betriebsorte.md))
- `SKILLS_SH_RELAY_URL` → `localRuntimeSkillsRelay`, in Compose voreingestellt
  ([Skills-Ordner](./skills-ordner.md), [Katalog](./skills-sh-katalog.md))

`LOCAL_RUNTIME_FIREBASE_API_KEY` ist der öffentliche Web-API-Key, kein Admin-
oder Kundengeheimnis.

## Siehe auch

- [Firebase-Wake-up der Runtime](./runtime-firebase-wakeup.md)
- [Lizenz-Token und Aktivierung](./lizenz-aktivierung.md)
