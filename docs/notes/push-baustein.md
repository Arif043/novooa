# Push-Benachrichtigung senden

> `notificationSend` schickt einen aufgelösten Text als Push an alle Mitglieder des Teams und liefert bewusst keinen Wert.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- `title` ist ebenfalls ein Template; ohne Wert „Benachrichtigung von novooa“.
- Leerer aufgelöster Text ist ein Run-Fehler.
- Kein Output und kein Ausgabename: Der Text ist dem Graphen aus der eigenen
  Konfiguration bekannt; ein Echo würde einen neuen Wert vortäuschen.
- Port `TeamNotificationSender`:
  - Cloud: `FirebaseTeamNotificationSender` löst Mitglieder über
    `TeamMembershipStore.memberUids` auf und sendet je Mitglied über
    `PushNotificationSender.sendToRecipient`; einzelne Fehlzustellungen werden
    protokolliert und brechen die übrigen nicht ab.
  - Standalone: Ein Team ist ein Arbeitsbereich ohne einzelne UIDs;
    `LocalTeamNotificationSender` sendet einmal über `RuntimePushRelayClient`
    an die registrierten Geräte der Lizenz.

## Siehe auch

- [Push-Benachrichtigungen in Standalone](./push-standalone.md)
- [Ergebnisvertrag eines Bausteins](./node-ergebnisvertrag.md)
