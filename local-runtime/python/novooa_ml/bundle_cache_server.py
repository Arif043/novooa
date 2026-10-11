import os
from http.server import ThreadingHTTPServer

from novooa_ml.bundles.bundle_file import bundle_files_from, validated_key
from novooa_ml.bundles.bundle_store import BundleStore
from novooa_ml.json_http import JsonRequestHandler
from novooa_ml.ml_service_config import global_store_from_environment, optional_bytes


class SharedBundleCache:
    """
    Gemeinsamer Cache globaler Modelle für alle Stacks eines Servers. Er ist der einzige Schreiber;
    die ML-Dienste binden das Verzeichnis nur lesend ein. Er enthält nur öffentliche Modelle, keine Kundendaten.
    """

    def __init__(self, store, global_store):
        self._store = store
        self._global_store = global_store

    def ensure(self, payload):
        files = bundle_files_from(payload.get("files"))
        if any(file.store_path is None for file in files):
            raise ValueError("Der gemeinsame Cache nimmt nur Dateien aus dem globalen Modellspeicher an.")
        key = validated_key(payload.get("modelKey"), files)
        self._store.install(key, files, self._global_store.fetch)
        return {"status": "ready"}


def handler_for(cache):
    class CacheHandler(JsonRequestHandler):
        def do_GET(self):
            self.respond(200, {"status": "ok"})

        def do_POST(self):
            if self.path != "/v1/bundles":
                self.respond(404, {"error": "Endpunkt nicht gefunden."})
                return
            try:
                self.respond(200, cache.ensure(self.read_json()))
            except Exception as error:
                self.respond(422, {"error": str(error)})

    return CacheHandler


def main():
    store = BundleStore(
        os.environ.get("MODEL_CACHE_DIR", "/var/lib/novooa-model-cache"), optional_bytes("MODEL_CACHE_MAX_BYTES"),
    )
    cache = SharedBundleCache(store, global_store_from_environment())
    port = int(os.environ.get("PORT", "8082"))
    host = os.environ.get("HOST", "127.0.0.1")
    ThreadingHTTPServer((host, port), handler_for(cache)).serve_forever()


if __name__ == "__main__":
    main()
