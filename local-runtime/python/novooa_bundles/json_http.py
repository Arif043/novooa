import json
from http.server import BaseHTTPRequestHandler


class JsonRequestHandler(BaseHTTPRequestHandler):
    """Gemeinsame Grundlage von ML-Dienst und Cache-Dienst: JSON lesen und antworten, ohne Zugriffsprotokoll."""

    def read_json(self):
        length = int(self.headers.get("content-length", "0"))
        return json.loads(self.rfile.read(length))

    def respond(self, status, body):
        content = json.dumps(body).encode("utf-8")
        self.send_response(status)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(content)))
        self.end_headers()
        self.wfile.write(content)

    def log_message(self, format_, *args):
        return
