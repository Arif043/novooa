# Web-Herkunftsregel

> Im Web gibt es keine Variantenwahl: Cloud-Domains starten Cloud, jede andere Herkunft ist die eigene Runtime.

Gehört zu: [Betriebsvarianten](../index/betriebsvarianten.md)

| Herkunft | Variante |
| --- | --- |
| `app.novooa.de`, `*.web.app`, `*.firebaseapp.com` | Cloud |
| jede andere Adresse (IP oder Domain der eigenen Runtime) | Standalone, Endpunkt = `Uri.base.origin` |

- Warum: einfacher und sicherer — eine Cloud-App kann nie gegen eine fremde
  Runtime sprechen und umgekehrt. Die Firebase-Hosting-Domains gehören dazu,
  sonst starteten Live-Deploy und PR-Vorschauen als Standalone.
- Ein gesetztes `--dart-define=NOVOOA_RUNTIME` gewinnt, damit
  `flutter run -d chrome` (auf `localhost`) weiter Cloud entwickeln kann.
- Reine Funktionen `isCloudWebHost(host)` und
  `webRuntimeKindForOrigin(uri)`, ohne direkten `Uri.base`-Zugriff testbar.
- `RuntimeConnectionCubit.initialize()` lädt im Web **keine** gespeicherte
  Adresse, sondern verbindet direkt zur Herkunft. Grund: Ein Überbleibsel
  (z. B. der entfernte Setup-Port `:8091`) ließ die App sonst dauerhaft gegen
  den falschen Port sprechen.

## Siehe auch

- [Die Runtime liefert die Web-App aus](./runtime-liefert-web-app.md)
- [Variantenwahl zur Laufzeit](./variantenwahl-zur-laufzeit.md)
