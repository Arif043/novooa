GLOBAL_SOURCE = "global"
TEAM_SOURCE = "team"


class BundleResolver:
    """
    Findet ein Bündel: globale Modelle liegen einmal pro Server und kommen aus dem globalen Modellspeicher;
    Teammodelle liegen im Speicher des Mandanten, die Runtime lädt sie hoch.
    """

    def __init__(self, global_bundles, global_store, team_stores):
        self._global_bundles = global_bundles
        self._global_store = global_store
        self._team_stores = team_stores

    def resolve(self, tenant, key, source, files):
        if source == TEAM_SOURCE:
            store = self._team_stores.store_for(tenant)
            return store.path_for(key) or store.complete_upload(key, files)
        if source != GLOBAL_SOURCE:
            raise ValueError("Die Quelle des Modellbündels ist unbekannt.")
        return self._global_bundles.install(key, files, self._global_store.fetch)

    def receive(self, tenant, key, file, stream, length):
        self._team_stores.store_for(tenant).receive(key, file, stream, length)

    def remove_tenant(self, tenant):
        self._team_stores.remove(tenant)
