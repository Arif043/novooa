# Benachrichtigungen und Push

> Freigaben werden als Notification an alle Team-Mitglieder verteilt und zusätzlich per FCM gepusht; im Web zeigt FCM Hintergrund-Pushes selbst an.

Gehört zu: [Architektur](../index/architektur.md)

- HITL-Freigaben: Notification `taskRunApproval` je Mitglied, dazu FCM-Push;
  im Client öffnet sie den Freigabe-Dialog.
- Nicht mehr registrierte Geräte-Tokens entfernt das Backend nach einer
  fehlgeschlagenen Zustellung; identische Tokens werden vor dem Versand
  dedupliziert.
- **Web:** FCM zeigt Hintergrund-Pushes an. Klick auf Desktop öffnet die
  Startseite, ohne die aktuelle Arbeit umzuleiten; mobile PWAs lesen den
  Payload und öffnen die Freigabe. Im Vordergrund erscheint eine Snackbar.
- **Standalone:** Der Client registriert sein Token nur über die Runtime; das
  Cloud-Relay prüft die Lizenz und versendet. Weder App noch Container haben
  Firebase-Admin- oder Messaging-Credentials
  ([Push in Standalone](./push-standalone.md)).

## Siehe auch

- [Push-Benachrichtigung senden](./push-baustein.md)
- [Freigaben und Pausen](./freigaben-und-pausen.md)
