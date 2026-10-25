# Changelog

## 0.2.0

- `RuntimeDevice` (App, Betriebssystem, Browser) meldet beim Login, beim
  Einlösen einer Einladung und beim Notzugang, welches Gerät sich anmeldet.
  `HttpRuntimeLoginClient` verlangt dafür `device:` und ist kein
  `const`-Aufruf ohne Argumente mehr:
  `HttpRuntimeLoginClient(device: RuntimeDevice.current(app: 'Mein Dashboard'))`.

## 0.1.0

- Erste Fassung, aus dem offiziellen Frontend ausgelagert: Adresse
  (`RuntimeEndpoint`), HTTP- und Binär-Client, Sitzungsende
  (`SessionAwareWorkspaceApiClient`), Echtzeit-Kanal, Token-Speicher,
  Anmeldung, Einladung, Notzugang, Ersteinrichtung und
  `RuntimeConnectionCubit`.
- Fehler als `RuntimeAccessFailure` statt fertiger Texte.
- Ohne verschlüsselten Transport-Tunnel: `http` nur im vertrauenswürdigen
  LAN, sonst `https` über einen Reverse Proxy.
