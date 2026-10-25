# Changelog

## 0.1.0

- Erste Fassung, aus dem offiziellen Frontend ausgelagert: Adresse
  (`RuntimeEndpoint`), HTTP- und Binär-Client, Sitzungsende
  (`SessionAwareWorkspaceApiClient`), Echtzeit-Kanal, Token-Speicher,
  Anmeldung, Einladung, Notzugang, Ersteinrichtung und
  `RuntimeConnectionCubit`.
- Fehler als `RuntimeAccessFailure` statt fertiger Texte.
- Ohne verschlüsselten Transport-Tunnel: `http` nur im vertrauenswürdigen
  LAN, sonst `https` über einen Reverse Proxy.
