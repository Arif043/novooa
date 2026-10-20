# Login-Ratenbegrenzung

> Anmeldung, Einladung einlösen und Notzugang begrenzen Versuche, bevor ein Passwort geprüft wird, und prüfen Passwörter nur einzeln nacheinander.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

`createLoginAttemptLimiter` (Token-Bucket im Arbeitsspeicher):

- je Client-Adresse 5 Versuche, danach 1 pro Minute;
- je Anmeldename ebenso 5 Versuche, danach 1 pro Minute — bremst das Raten
  gegen ein Konto von vielen Adressen und hinter einem Reverse Proxy;
- über alle Clients 10 Versuche, danach 1 alle 5 Sekunden — höchstens etwa
  12 Prüfungen pro Minute, auch bei vielen Angreifer-Adressen.

Darüber: `429` mit `Retry-After`. Gemerkt werden höchstens 10 000 Adressen
(die am längsten ungenutzte fällt zuerst weg). Hinter einem Reverse Proxy ist
die Client-Adresse die des Proxys; die Client-Stufe gilt dann für alle
gemeinsam, die Stufe je Anmeldename greift weiter. Unbekannte Anmeldenamen
kosten gleich viel Zeit wie bekannte, damit sie nicht erkennbar sind.

Die Prüfung (scrypt, N=2^17, ~128 MiB) läuft asynchron im libuv-Threadpool und
immer nur einmal gleichzeitig. Warum: Der Event-Loop bleibt frei, und parallele
Versuche belegen nicht je eigene 128 MiB.

## Siehe auch

- [Passwort ändern](./passwort-aendern.md)
- [Reverse Proxy für externen Zugriff](./reverse-proxy-externer-zugriff.md)
