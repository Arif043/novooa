import io
import os
import tempfile
import unittest
from pathlib import Path

from bundle_test_support import TENANT_A, TENANT_B, FakeGlobalStore, bundle_file
from novooa_bundles.bundle_file import BundleFile, BundleFilesMissing, bundle_files_from, bundle_key, validate_bundle_path
from novooa_bundles.bundle_store import BundleStore
from novooa_ml.bundles.bundle_resolver import BundleResolver
from novooa_ml.bundles.team_stores import TeamStores

MODEL = b"model"
WEIGHTS = b"weights" * 10


class BundleFileTest(unittest.TestCase):
    def test_the_key_depends_on_paths_and_checksums_not_on_order(self):
        first = [bundle_file("model.onnx", MODEL), bundle_file("model.onnx.data", WEIGHTS)]

        self.assertEqual(bundle_key(first), bundle_key(list(reversed(first))))
        self.assertNotEqual(bundle_key(first), bundle_key([bundle_file("model.onnx", MODEL)]))

    def test_matches_the_key_the_runtime_computes(self):
        # Derselbe Wert wie modelBundleKey in functions/src — sonst finden sich die Bündel nicht.
        files = [BundleFile("model.onnx", "a" * 64, 1), BundleFile("model.onnx.data", "b" * 64, 1)]

        self.assertEqual(bundle_key(files), "c8e755d5630fe72fa98c65159d88d862083396d6896a80a253a87cc784bd1a52")

    def test_accepts_model_external_data_and_resources_only(self):
        for path in ["model.onnx", "model.onnx.data", "resources/labels.json"]:
            self.assertEqual(validate_bundle_path(path), path)
        for path in ["../x", "resources", "resources/a/b", "/etc/passwd", "a/b", ".hidden"]:
            with self.assertRaises(ValueError):
                validate_bundle_path(path)

    def test_requires_the_model_file(self):
        with self.assertRaises(ValueError):
            bundle_files_from([{"path": "labels", "sha256": "a" * 64, "sizeBytes": 1}])


class BundleStoreTest(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp())
        self.files = [bundle_file("model.onnx", MODEL), bundle_file("model.onnx.data", WEIGHTS)]
        self.key = bundle_key(self.files)

    def test_installs_a_bundle_once_and_reuses_it(self):
        store, source = BundleStore(self.root), FakeGlobalStore({"model.onnx": MODEL, "model.onnx.data": WEIGHTS})

        first = store.install(self.key, self.files, source.fetch)
        second = store.install(self.key, self.files, source.fetch)

        self.assertEqual(first, second)
        self.assertEqual((first / "model.onnx.data").read_bytes(), WEIGHTS)
        self.assertEqual(source.fetched, ["model.onnx", "model.onnx.data"])

    def test_discards_a_bundle_whose_file_does_not_match_its_checksum(self):
        store = BundleStore(self.root)

        with self.assertRaises(ValueError):
            store.install(self.key, self.files, FakeGlobalStore({"model.onnx": MODEL, "model.onnx.data": b"x"}).fetch)

        self.assertIsNone(store.path_for(self.key))

    def test_evicts_the_least_recently_used_bundle_beyond_the_budget(self):
        store = BundleStore(self.root, maximum_bytes=len(MODEL) * 2)
        old, new = [bundle_file("model.onnx", MODEL)], [bundle_file("model.onnx", b"other")]
        os.utime(store.install(bundle_key(old), old, FakeGlobalStore({"model.onnx": MODEL}).fetch), (1, 1))
        store.install(bundle_key(new), new, FakeGlobalStore({"model.onnx": b"other"}).fetch)
        newest = [bundle_file("model.onnx", b"third")]

        store.install(bundle_key(newest), newest, FakeGlobalStore({"model.onnx": b"third"}).fetch)

        self.assertIsNone(store.path_for(bundle_key(old)))
        self.assertIsNotNone(store.path_for(bundle_key(newest)))

    def test_keeps_the_bundle_another_process_published_first(self):
        source = FakeGlobalStore({"model.onnx": MODEL, "model.onnx.data": WEIGHTS})
        BundleStore(self.root).install(self.key, self.files, source.fetch)
        # Ein zweiter Prozess hat parallel dasselbe Bündel gebaut.
        late = _built(self.root, self.files, source)

        path = BundleStore(self.root)._publish(self.key, late)

        self.assertEqual((path / "model.onnx").read_bytes(), MODEL)
        self.assertFalse(late.exists())

    def test_completes_an_uploaded_bundle_only_when_all_files_arrived(self):
        store = BundleStore(self.root)
        store.receive(self.key, self.files[0], io.BytesIO(MODEL), len(MODEL))

        with self.assertRaises(BundleFilesMissing) as missing:
            store.complete_upload(self.key, self.files)
        store.receive(self.key, self.files[1], io.BytesIO(WEIGHTS), len(WEIGHTS))

        self.assertEqual(missing.exception.missing, ["model.onnx.data"])
        self.assertEqual((store.complete_upload(self.key, self.files) / "model.onnx").read_bytes(), MODEL)


class BundleResolverTest(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp())
        self.files = [bundle_file("model.onnx", MODEL, "model-artifacts/a/versions/1/model.onnx")]
        self.key = bundle_key(self.files)
        self.teams = TeamStores(self.root / "teams")

    def resolver(self, source):
        return BundleResolver(BundleStore(self.root / "global"), source, self.teams)

    def test_downloads_global_bundles_once_for_all_tenants(self):
        source = FakeGlobalStore({"model.onnx": MODEL})
        resolver = self.resolver(source)

        first = resolver.resolve(TENANT_A, self.key, "global", self.files)
        second = resolver.resolve(TENANT_B, self.key, "global", self.files)

        self.assertEqual(first, second)
        self.assertEqual(source.fetched, ["model.onnx"])

    def test_team_bundles_must_be_uploaded_by_the_runtime(self):
        with self.assertRaises(BundleFilesMissing):
            self.resolver(FakeGlobalStore({})).resolve(TENANT_A, self.key, "team", self.files)

    def test_team_bundles_of_one_tenant_are_invisible_to_another(self):
        resolver = self.resolver(FakeGlobalStore({}))
        resolver.receive(TENANT_A, self.key, self.files[0], io.BytesIO(MODEL), len(MODEL))

        self.assertIsNotNone(resolver.resolve(TENANT_A, self.key, "team", self.files))
        with self.assertRaises(BundleFilesMissing):
            resolver.resolve(TENANT_B, self.key, "team", self.files)

    def test_removing_a_tenant_deletes_its_team_bundles(self):
        resolver = self.resolver(FakeGlobalStore({}))
        resolver.receive(TENANT_A, self.key, self.files[0], io.BytesIO(MODEL), len(MODEL))
        resolver.resolve(TENANT_A, self.key, "team", self.files)

        resolver.remove_tenant(TENANT_A)

        self.assertFalse((self.root / "teams" / TENANT_A.registration).exists())


def _built(root, files, source):
    building = root / ".building" / "other"
    for file in files:
        destination = building / file.path
        destination.parent.mkdir(parents=True, exist_ok=True)
        source.fetch(file, destination)
    return building


if __name__ == "__main__":
    unittest.main()
