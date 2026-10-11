import json
import urllib.error
import urllib.request

ENSURE_TIMEOUT_SECONDS = 3600


class SharedCacheClient:
    """Bittet den Cache-Dienst des Servers, ein globales Bündel bereitzustellen (er ist dessen einziger Schreiber)."""

    def __init__(self, base_url):
        self._url = base_url.rstrip("/") + "/v1/bundles"

    def ensure(self, key, files):
        body = json.dumps({"modelKey": key, "files": [_file_json(file) for file in files]}).encode("utf-8")
        request = urllib.request.Request(
            self._url, data=body, method="POST", headers={"content-type": "application/json"},
        )
        try:
            with urllib.request.urlopen(request, timeout=ENSURE_TIMEOUT_SECONDS):
                return
        except urllib.error.HTTPError as error:
            raise ValueError(_error_message(error)) from error


def _file_json(file):
    return {"path": file.path, "sha256": file.sha256, "sizeBytes": file.size_bytes, "storePath": file.store_path}


def _error_message(error):
    try:
        return json.loads(error.read()).get("error") or "Der Modell-Cache ist nicht erreichbar."
    except ValueError:
        return "Der Modell-Cache ist nicht erreichbar."
