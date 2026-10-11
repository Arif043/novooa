import io
import os
import tempfile
import unittest
from pathlib import Path

from bundle_test_support import FakeGlobalStore, bundle_file
from novooa_ml.bundles.bundle_file import BundleFile, BundleFilesMissing, bundle_files_from, bundle_key, validate_bundle_path
from novooa_ml.bundles.bundle_resolver import BundleResolver
from novooa_ml.bundles.bundle_store import BundleStore

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
        # Ein zweiter Cache-Dienst auf demselben Server hat parallel dasselbe Bündel gebaut.
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

    def test_downloads_global_bundles_into_its_own_store_without_a_shared_cache(self):
        source = FakeGlobalStore({"model.onnx": MODEL})
        resolver = BundleResolver(BundleStore(self.root), source)

        path = resolver.resolve(self.key, "global", self.files)

        self.assertEqual((path / "model.onnx").read_bytes(), MODEL)

    def test_asks_the_shared_cache_and_reads_its_directory(self):
        shared = Path(tempfile.mkdtemp())
        cache = RecordingSharedCache(shared, MODEL)
        resolver = BundleResolver(BundleStore(self.root), FakeGlobalStore({}), shared, cache)

        path = resolver.resolve(self.key, "global", self.files)

        self.assertEqual(path, shared / self.key)
        self.assertEqual(cache.keys, [self.key])

    def test_team_bundles_must_be_uploaded_by_the_runtime(self):
        resolver = BundleResolver(BundleStore(self.root), FakeGlobalStore({}))

        with self.assertRaises(BundleFilesMissing):
            resolver.resolve(self.key, "team", self.files)


def _built(root, files, source):
    building = root / ".building" / "other"
    for file in files:
        destination = building / file.path
        destination.parent.mkdir(parents=True, exist_ok=True)
        source.fetch(file, destination)
    return building


class RecordingSharedCache:
    def __init__(self, directory, content):
        self.directory, self.content, self.keys = directory, content, []

    def ensure(self, key, files):
        self.keys.append(key)
        (self.directory / key).mkdir()
        (self.directory / key / "model.onnx").write_bytes(self.content)


if __name__ == "__main__":
    unittest.main()
