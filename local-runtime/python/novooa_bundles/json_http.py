import json
from http.server import BaseHTTPRequestHandler


class JsonRequestHandler(BaseHTTPRequestHandler):
    """Grundlage der HTTP-Dienste: JSON lesen und antworten, ohne Zugriffsprotokoll."""

    def read_json(self):
        length = int(self.headers.get("content-length", "0"))
        return json.loads(self.rfile.read(length))

    def respond(self, status, body, headers=None):
        content = json.dumps(body).encode("utf-8")
        self.send_response(status)
        for name, value in (headers or {}).items():
            self.send_header(name, value)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(content)))
        self.end_headers()
        self.wfile.write(content)

    def log_message(self, format_, *args):
        return
