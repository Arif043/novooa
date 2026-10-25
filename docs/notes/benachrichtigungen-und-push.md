# Benachrichtigungen und Push

> Freigaben erscheinen als Benachrichtigung in der App und werden, wenn Push aktiv ist, über das Push-Relay per FCM zugestellt.

Gehört zu: [Architektur](../index/architektur.md)

- HITL-Freigaben: Notification `taskRunApproval`, dazu FCM-Push; im Client
  öffnet sie den Freigabe-Dialog.
- Nicht mehr registrierte Geräte-Tokens entfernt das Backend nach einer
  fehlgeschlagenen Zustellung; identische Tokens werden vor dem Versand
  dedupliziert.
- **Web:** FCM zeigt Hintergrund-Pushes an; ein Klick öffnet die Web-App
  unter der Adresse der Runtime oder holt ein offenes Fenster nach vorn
  (`web/firebase-messaging-sw.js`). Im Vordergrund erscheint eine Snackbar.
- Der Client registriert sein Token nur über die Runtime; das Push-Relay
  prüft die Lizenz und versendet. Weder App noch Container haben
  Firebase-Admin- oder Messaging-Credentials
  ([Push über das Relay](./push-standalone.md)).

## Siehe auch

- [Push-Benachrichtigung senden](./push-baustein.md)
- [Freigaben und Pausen](./freigaben-und-pausen.md)
