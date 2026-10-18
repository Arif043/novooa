import json
import os
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from novooa_packages.installer import EnvironmentInstaller, InstallFailed
from novooa_packages.requirements import RequirementInvalid, checked_environment_id, checked_packages

MAX_BODY_BYTES = 64 * 1024
_ENVIRONMENT_PATH = re.compile(r"^/environments/([^/]+)$")


def installer_from_environment():
    return EnvironmentInstaller(
        os.environ.get("SCRIPT_PACKAGES_ROOT", "/packages"),
        int(os.environ.get("SCRIPT_PACKAGES_MAX_ENVIRONMENT_BYTES", str(2 * 1024 ** 3))),
    )


class PackagesHandler(BaseHTTPRequestHandler):
    server_version = "novooa-packages"
    installer = None

    def do_GET(self):
        if self.path == "/healthz":
            return self.reply(200, {"status": "ok"})
        if self.path == "/environments":
            return self.reply(200, {"items": self.installer.list()})
        self.reply(404, {"error": "Nicht gefunden."})

    def do_POST(self):
        if self.path != "/environments":
            return self.reply(404, {"error": "Nicht gefunden."})
        try:
            request = self.read_json()
            environment_id = checked_environment_id(request.get("id"))
            packages = checked_packages(request.get("packages"))
        except (RequirementInvalid, ValueError) as error:
            return self.reply(400, {"error": str(error)})
        try:
            self.reply(200, self.installer.install(environment_id, packages))
        except InstallFailed as failure:
            self.reply(422, {"reason": failure.reason, "detail": failure.detail})
        except Exception:  # noqa: BLE001 - nie die Verbindung kappen, sondern sauber antworten
            self.reply(500, {"reason": "failed", "detail": "Interner Fehler im Paketdienst."})

    def do_DELETE(self):
        match = _ENVIRONMENT_PATH.match(self.path)
        if match is None:
            return self.reply(404, {"error": "Nicht gefunden."})
        try:
            self.installer.delete(checked_environment_id(match.group(1)))
        except RequirementInvalid as error:
            return self.reply(400, {"error": str(error)})
        self.reply(204, None)

    def read_json(self):
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0 or length > MAX_BODY_BYTES:
            raise ValueError("Die Anfrage ist leer oder zu groß.")
        request = json.loads(self.rfile.read(length))
        if not isinstance(request, dict):
            raise ValueError("Die Anfrage ist ungültig.")
        return request

    def reply(self, status, body):
        data = b"" if body is None else json.dumps(body).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, format, *args):
        pass


def main():
    PackagesHandler.installer = installer_from_environment()
    port = int(os.environ.get("PORT", "8092"))
    ThreadingHTTPServer((os.environ.get("HOST", "0.0.0.0"), port), PackagesHandler).serve_forever()


if __name__ == "__main__":
    main()
