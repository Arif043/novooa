# Reverse Proxy für externen Zugriff

> Aus dem Internet ist die Runtime nur über einen eigenen Reverse Proxy mit Domain und Zertifikat erreichbar; Port `8090` bleibt dann auf den Host beschränkt.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Der Proxy terminiert TLS und leitet an `127.0.0.1:8090` weiter. Der Client
erkennt die Domain und nutzt HTTPS. Minimales nginx-Beispiel:

```nginx
server {
    listen 443 ssl;
    server_name novooa.example.de;

    ssl_certificate     /etc/letsencrypt/live/novooa.example.de/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/novooa.example.de/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8090;
        proxy_set_header Host $host;
    }
}
```

Damit die Runtime nicht zusätzlich direkt erreichbar bleibt, wird
`NOVOOA_RUNTIME_BIND_ADDRESS=127.0.0.1` gesetzt. Die gemeinsame
`docker-compose.local.yaml` bindet den Host-Port dann nur an Loopback.
Für [Coolify](./coolify-deployment.md) sind Proxy-Netz und HTTPS-Router
bereits enthalten und werden über Umgebungsvariablen aktiviert.

Warum zwingend: Über `http` laufen Session-Token und Inhalte im Klartext.
Webhooks setzen diesen Aufbau ebenfalls voraus.

## Siehe auch

- [Transportverschlüsselung ist Infrastruktur](./transport-ist-infrastruktur.md)
- [Login-Ratenbegrenzung](./login-ratenbegrenzung.md) — Client-Adresse hinter dem Proxy
