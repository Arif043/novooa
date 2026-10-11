from novooa_bundles.file_transfer import download_verified


class GlobalModelStore:
    """Der öffentlich lesbare globale Modellspeicher (S3-kompatibel), adressiert über Speicherpfade."""

    def __init__(self, base_url):
        if not base_url or not base_url.startswith(("https://", "http://")):
            raise ValueError("MODEL_STORE_URL muss eine HTTP(S)-Adresse sein.")
        self._base_url = base_url.rstrip("/")

    def fetch(self, file, destination):
        if file.store_path is None:
            raise ValueError(f"Für {file.path} fehlt der Pfad im globalen Modellspeicher.")
        download_verified(f"{self._base_url}/{file.store_path}", destination, file)


class UnavailableGlobalModelStore:
    def fetch(self, file, destination):
        raise ValueError("Der globale Modellspeicher ist nicht konfiguriert (MODEL_STORE_URL).")
