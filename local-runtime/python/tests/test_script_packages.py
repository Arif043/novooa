import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_packages.installer import EnvironmentInstaller, InstallFailed, reason_of
from novooa_packages.requirements import RequirementInvalid, checked_environment_id, checked_packages

ENVIRONMENT_ID = "a" * 64


class FakeUv:
    """Spielt uv: `compile` schreibt lock.txt, `install` legt Dateien in site/ an."""

    def __init__(self, fail_with=None, site_bytes=10):
        self.fail_with = fail_with
        self.site_bytes = site_bytes
        self.calls = []

    def __call__(self, command, cwd, **_):
        self.calls.append(command[1:3])
        if self.fail_with:
            return SimpleNamespace(returncode=1, stderr=self.fail_with)
        if command[2] == "compile":
            Path(cwd, "lock.txt").write_text("six==1.16.0 --hash=sha256:x\n")
        else:
            site = Path(cwd, "site")
            site.mkdir()
            (site / "six.py").write_bytes(b"x" * self.site_bytes)
        return SimpleNamespace(returncode=0, stderr="")


class RequirementsTest(unittest.TestCase):
    def test_accepts_names_extras_and_versions(self):
        packages = ["pandas", " pandas==2.2.3 ", "requests[socks]>=2.31,<3", "opencv-python~=4.10"]

        self.assertEqual(checked_packages(packages)[1], "pandas==2.2.3")

    def test_rejects_urls_paths_and_options(self):
        for package in ["https://evil.example/x.whl", "./lokal", "--index-url=http://x", "pkg @ http://x", "a;b", ""]:
            with self.assertRaises(RequirementInvalid, msg=package):
                checked_packages([package])

    def test_rejects_ids_that_are_not_a_hash(self):
        with self.assertRaises(RequirementInvalid):
            checked_environment_id("../etc")


class InstallerTest(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp())

    def tearDown(self):
        shutil.rmtree(self.root, ignore_errors=True)

    def test_builds_an_environment_and_lists_it(self):
        uv = FakeUv()
        installer = EnvironmentInstaller(self.root, 1000, run=uv)

        metadata = installer.install(ENVIRONMENT_ID, ["six"])

        self.assertEqual(metadata, {"id": ENVIRONMENT_ID, "packages": ["six"], "sizeBytes": 10})
        self.assertTrue((self.root / "envs" / ENVIRONMENT_ID / "site" / "six.py").is_file())
        self.assertTrue((self.root / "envs" / ENVIRONMENT_ID / "lock.txt").is_file())
        self.assertEqual(installer.list(), [metadata])
        self.assertEqual(uv.calls, [["pip", "compile"], ["pip", "install"]])
        self.assertEqual(list((self.root / ".building").iterdir()), [])

    def test_an_existing_environment_is_not_built_again(self):
        uv = FakeUv()
        installer = EnvironmentInstaller(self.root, 1000, run=uv)
        installer.install(ENVIRONMENT_ID, ["six"])

        installer.install(ENVIRONMENT_ID, ["six"])

        self.assertEqual(len(uv.calls), 2)

    def test_too_large_environments_are_removed(self):
        installer = EnvironmentInstaller(self.root, 5, run=FakeUv(site_bytes=10))

        with self.assertRaises(InstallFailed) as raised:
            installer.install(ENVIRONMENT_ID, ["six"])

        self.assertEqual(raised.exception.reason, "tooLarge")
        self.assertEqual(installer.list(), [])

    def test_uv_failures_carry_a_reason_and_leave_nothing_behind(self):
        installer = EnvironmentInstaller(self.root, 1000, run=FakeUv(
            fail_with="  × No solution found\n  ╰─▶ Because gibtsnicht was not found in the package registry",
        ))

        with self.assertRaises(InstallFailed) as raised:
            installer.install(ENVIRONMENT_ID, ["gibtsnicht"])

        self.assertEqual(raised.exception.reason, "notFound")
        self.assertIn("gibtsnicht", raised.exception.detail)
        self.assertFalse((self.root / "envs" / ENVIRONMENT_ID).exists())

    def test_deletes_an_environment(self):
        installer = EnvironmentInstaller(self.root, 1000, run=FakeUv())
        installer.install(ENVIRONMENT_ID, ["six"])

        installer.delete(ENVIRONMENT_ID)

        self.assertEqual(installer.list(), [])

    def test_recognizes_missing_wheels(self):
        self.assertEqual(reason_of("error: x has no wheels with a matching platform tag and --only-binary"), "noWheel")


@unittest.skipUnless(shutil.which("uv"), "uv ist nur im Image des Paketdienstes installiert")
class RealInstallTest(unittest.TestCase):
    def test_installs_a_small_package_from_pypi(self):
        root = Path(tempfile.mkdtemp())
        try:
            metadata = EnvironmentInstaller(root, 10 * 1024 ** 2).install(ENVIRONMENT_ID, ["six==1.16.0"])
            site = root / "envs" / ENVIRONMENT_ID / "site"
            version = subprocess.run(
                [sys.executable, "-c", "import six; print(six.__version__)"],
                env={"PYTHONPATH": str(site)}, capture_output=True, text=True, check=True,
            ).stdout.strip()
        finally:
            shutil.rmtree(root, ignore_errors=True)

        self.assertEqual(version, "1.16.0")
        self.assertGreater(metadata["sizeBytes"], 0)


if __name__ == "__main__":
    unittest.main()
