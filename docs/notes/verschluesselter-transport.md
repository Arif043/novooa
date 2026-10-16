# Verschlüsselter Transport über http

> Über `http` tunnelt der Client jede JSON-Anfrage an `/v1/…` verschlüsselt (X25519 + HKDF + AES-256-GCM); die Routen bleiben unverändert.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

1. **Handshake** `POST /v1/secure/handshake`: ephemere X25519-Schlüssel und je
   eine 16-Byte-Nonce. HKDF-SHA256 (Salt = Client-Nonce ‖ Server-Nonce, Info
   `novooa-transport-v1`) leitet je Richtung einen Schlüssel ab. Die Runtime
   hält den Kanal im Speicher (Leerlauf 12 h, höchstens 512 Kanäle); nach
   ihrem Neustart handelt der Client neu aus.
2. **Austausch** `POST /v1/secure/exchange`: Methode, Pfad samt Query,
   `Authorization`, `Content-Type` und Body als JSON mit AES-256-GCM
   (Umschlag = Base64(IV ‖ Chiffretext ‖ Tag), Zusatzdaten
   `novooa/1|<Kanal>|<req|res>|<Zähler>`). Die Runtime führt die Anfrage intern
   gegen die normalen Routen aus, inklusive Lizenz- und Session-Prüfung.
3. **Wiedereinspielschutz:** Jeder Zähler gilt einmal und muss im Fenster der
   letzten 128 liegen, damit parallele Anfragen sich überholen dürfen. Ein
   Zähler wird erst nach erfolgreicher Entschlüsselung verbraucht.
4. **Umfang:** nur `GET/POST/PUT/DELETE` auf `/v1/…` (nicht `/v1/secure/…`)
   mit JSON-Antwort. `/healthz`, Datei-Up/-Downloads außerhalb der JSON-API,
   WebSocket und die Web-App selbst laufen im Klartext.

**Kein Rückfall auf Klartext:** Kennt die Runtime den Handshake nicht, meldet
der Client eine Verbindungsstörung mit dem Hinweis zu aktualisieren. Bei
`https` entfällt der Tunnel.

**Grenzen:** Der Handshake ist nicht authentifiziert; ein aktiver
Man-in-the-Middle kann mitlesen (Abhilfe wäre Trust on First Use oder TLS).
Die Runtime akzeptiert weiter Klartext-Anfragen und kann einen mitgeschnittenen
Token (etwa aus einem Upload) nicht von einem Tunnel-Token unterscheiden.

Code: `functions/src/shared/local/secure-transport-*.ts` und
`lib/core/network/secure_transport/`. Ein gemeinsamer Testvektor und
gegenseitig erzeugte Umschläge sichern die Kompatibilität.

## Siehe auch

- [Transportverschlüsselung ist Infrastruktur](./transport-ist-infrastruktur.md)
- [Reverse Proxy für externen Zugriff](./reverse-proxy-externer-zugriff.md)
