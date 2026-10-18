import json
import shutil
import sys
import tempfile
import threading
import unittest
import urllib.request
from http.server import ThreadingHTTPServer
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_script import execution, package_probe
from novooa_script.server import ScriptHandler

ENVIRONMENT = "d" * 64


class FakeEnvironment:
    """Eine Umgebung wie vom Paketdienst: Module im `site`-Verzeichnis, RECORD je Distribution."""

    def __init__(self):
        self.root = Path(tempfile.mkdtemp())
        self.site = self.root / "envs" / ENVIRONMENT / "site"
        self.site.mkdir(parents=True)

    def add(self, distribution, files):
        record = self.site / f"{distribution}-1.0.dist-info" / "RECORD"
        record.parent.mkdir()
        for path, content in files.items():
            (self.site / path).parent.mkdir(parents=True, exist_ok=True)
            (self.site / path).write_text(content)
        record.write_text("".join(f"{path},sha256=x,1\n" for path in [*files, str(record.relative_to(self.site))]))

    def remove(self):
        shutil.rmtree(self.root, ignore_errors=True)


class ProbeTest(unittest.TestCase):
    def setUp(self):
        self.environment = FakeEnvironment()
        self.original = execution.PACKAGES_ROOT
        execution.PACKAGES_ROOT = str(self.environment.root)

    def tearDown(self):
        execution.PACKAGES_ROOT = self.original
        self.environment.remove()

    def probe(self, *packages):
        return package_probe.probe({"environment": ENVIRONMENT, "packages": list(packages)})

    def test_finds_the_top_level_modules_of_the_requested_distributions_only(self):
        self.environment.add("Opencv_Python_Headless", {
            "cv2/__init__.py": "", "cv2/data/x.py": "", "opencv_python_headless.libs/libz.so": "", "bin/tool": "",
        })
        self.environment.add("PyYAML", {"yaml/__init__.py": "", "_yaml/__init__.py": ""})
        self.environment.add("abhaengig", {"abhaengig.py": ""})

        modules = package_probe.modules_of(str(self.environment.site), ["opencv-python-headless", "pyyaml>=6"])

        self.assertEqual(modules, ["cv2", "yaml"])

    def test_loadable_packages_pass(self):
        self.environment.add("paket", {"paket/__init__.py": "WERT = 1\n"})

        self.assertEqual(self.probe("paket==1.0"), {"loadable": True})

    def test_names_the_module_that_cannot_be_loaded(self):
        self.environment.add("gut", {"gut.py": ""})
        self.environment.add("kaputt", {"kaputt/__init__.py": "raise ImportError('libpango-1.0.so.0: cannot open shared object file')\n"})

        verdict = self.probe("gut", "kaputt")

        self.assertEqual(verdict, {
            "loadable": False, "module": "kaputt",
            "error": "ImportError: libpango-1.0.so.0: cannot open shared object file",
        })

    def test_a_slow_import_fails_with_the_time_limit(self):
        self.environment.add("langsam", {"langsam.py": "import time\ntime.sleep(5)\n"})
        original = execution.TIMEOUT_SECONDS
        execution.TIMEOUT_SECONDS = 0.5
        try:
            verdict = self.probe("langsam")
        finally:
            execution.TIMEOUT_SECONDS = original

        self.assertEqual(verdict, {"loadable": False, "module": None, "error": "Der Import dauerte länger als 0.5 Sekunden."})

    def test_a_missing_environment_is_reported(self):
        with self.assertRaises(execution.PackagesMissing):
            package_probe.probe({"environment": "e" * 64, "packages": ["paket"]})
        with self.assertRaises(execution.PackagesMissing):
            package_probe.probe({"packages": ["paket"]})


class ProbeEndpointTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), ScriptHandler)
        threading.Thread(target=cls.server.serve_forever, daemon=True).start()
        cls.url = f"http://127.0.0.1:{cls.server.server_address[1]}/probe"

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()

    def post(self, body):
        request = urllib.request.Request(self.url, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(request) as response:
                return response.status, json.load(response)
        except urllib.error.HTTPError as error:
            return error.code, json.load(error)

    def test_answers_with_the_verdict(self):
        environment = FakeEnvironment()
        original = execution.PACKAGES_ROOT
        execution.PACKAGES_ROOT = str(environment.root)
        try:
            environment.add("paket", {"paket.py": ""})
            self.assertEqual(self.post({"environment": ENVIRONMENT, "packages": ["paket"]}), (200, {"loadable": True}))
            self.assertEqual(self.post({"environment": "f" * 64, "packages": ["paket"]})[0], 409)
        finally:
            execution.PACKAGES_ROOT = original
            environment.remove()

    def test_rejects_a_request_without_packages(self):
        self.assertEqual(self.post({"environment": ENVIRONMENT})[0], 400)


if __name__ == "__main__":
    unittest.main()
