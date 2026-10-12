import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import ml_test_support  # noqa: F401  (setzt den Paketpfad)
from novooa_ml.resource_limits import available_cpus, available_memory_bytes, resource_limits_from_environment


class ResourceLimitsTest(unittest.TestCase):
    def setUp(self):
        self.cgroup = Path(tempfile.mkdtemp())

    def test_reads_the_cpu_quota_and_memory_limit_of_the_container(self):
        (self.cgroup / "cpu.max").write_text("200000 100000\n")
        (self.cgroup / "memory.max").write_text("1000\n")

        self.assertEqual(available_cpus(self.cgroup), min(2, host_cpus()))
        self.assertEqual(available_memory_bytes(self.cgroup), 1000)

    def test_falls_back_to_the_host_without_limits(self):
        (self.cgroup / "cpu.max").write_text("max 100000\n")
        (self.cgroup / "memory.max").write_text("max\n")

        self.assertEqual(available_cpus(self.cgroup), host_cpus())
        self.assertGreater(available_memory_bytes(self.cgroup), 1000)

    def test_derives_slots_threads_and_session_budget(self):
        (self.cgroup / "memory.max").write_text("1000\n")
        with patch("novooa_ml.resource_limits.available_cpus", return_value=8), patch.dict(os.environ, {}, clear=True):
            limits = resource_limits_from_environment(self.cgroup)

        self.assertEqual((limits.intra_op_threads, limits.compute_slots, limits.session_bytes), (4, 2, 700))

    def test_environment_overrides_the_defaults(self):
        overrides = {"ML_INTRA_OP_THREADS": "1", "ML_COMPUTE_SLOTS": "3", "MODEL_SESSION_CACHE_BYTES": "42"}
        with patch.dict(os.environ, overrides, clear=True):
            limits = resource_limits_from_environment(self.cgroup)

        self.assertEqual((limits.intra_op_threads, limits.compute_slots, limits.session_bytes), (1, 3, 42))


def host_cpus():
    return len(os.sched_getaffinity(0)) if hasattr(os, "sched_getaffinity") else os.cpu_count()


if __name__ == "__main__":
    unittest.main()
