import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import BoundedSemaphore

from novooa_script.execution import ScriptFailed, execute
from novooa_script.multipart import MultipartError, parse_multipart

MAX_BODY_BYTES = 64 * 1024 * 1024
MAX_PARALLEL_RUNS = int(os.environ.get("SCRIPT_MAX_PARALLEL_RUNS", "4"))
QUEUE_WAIT_SECONDS = 30
_slots = BoundedSemaphore(MAX_PARALLEL_RUNS)


class RequestInvalid(Exception):
    pass


class ScriptHandler(BaseHTTPRequestHandler):
    server_version = "novooa-script"

    def do_GET(self):
        if self.path == "/healthz":
            return self.reply(200, {"status": "ok"})
        self.reply(404, {"error": "Nicht gefunden."})

    def do_POST(self):
        if self.path != "/run":
            return self.reply(404, {"error": "Nicht gefunden."})
        try:
            request, files = self.read_request()
        except RequestInvalid as error:
            return self.reply(400, {"error": str(error)})
        self.run(request, files)

    def run(self, request, files):
        if not _slots.acquire(timeout=QUEUE_WAIT_SECONDS):
            return self.reply(503, {"error": "Der Script-Dienst ist ausgelastet."})
        try:
            self.reply(200, execute(request, files))
        except ScriptFailed as error:
            self.reply(422, {"error": str(error), "printed": error.printed, "stderr": error.error_output})
        except Exception:  # noqa: BLE001 - nie die Verbindung kappen, sondern sauber antworten
            self.reply(500, {"error": "Im Script-Dienst ist ein interner Fehler aufgetreten."})
        finally:
            _slots.release()

    def read_request(self):
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0 or length > MAX_BODY_BYTES:
            raise RequestInvalid("Die Anfrage ist leer oder zu groß.")
        try:
            parts = parse_multipart(self.headers.get("Content-Type", ""), self.rfile.read(length))
            request = json.loads(parts["request"])
            files = [parts[f"file-{index}"] for index in range(len(request.get("files", [])))]
        except (MultipartError, KeyError, ValueError) as error:
            raise RequestInvalid(f"Die Anfrage ist ungültig: {error}")
        if not isinstance(request.get("script"), str):
            raise RequestInvalid("Die Anfrage enthält kein Script.")
        request.setdefault("input", "")
        request.setdefault("variables", {})
        return request, files

    def reply(self, status, body):
        data = json.dumps(body).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, format, *args):
        pass


def main():
    port = int(os.environ.get("PORT", "8091"))
    ThreadingHTTPServer((os.environ.get("HOST", "0.0.0.0"), port), ScriptHandler).serve_forever()


if __name__ == "__main__":
    main()
