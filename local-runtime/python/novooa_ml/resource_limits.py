import os
from dataclasses import dataclass
from pathlib import Path

from novooa_bundles.environment import optional_positive_int

CGROUP_ROOT = Path("/sys/fs/cgroup")
SESSION_SHARE_OF_MEMORY = 0.7
MAXIMUM_DEFAULT_THREADS = 4


@dataclass(frozen=True)
class ResourceLimits:
    compute_slots: int
    intra_op_threads: int
    session_bytes: int


def resource_limits_from_environment(cgroup_root=CGROUP_ROOT):
    """
    Richtet sich nach dem, was dem Container zusteht (cgroup), nicht nach der Größe des Servers: Auf demselben
    Server laufen auch die Runtimes. Explizite Umgebungsvariablen haben Vorrang.
    """
    cpus = available_cpus(cgroup_root)
    threads = optional_positive_int("ML_INTRA_OP_THREADS", min(MAXIMUM_DEFAULT_THREADS, cpus))
    return ResourceLimits(
        compute_slots=optional_positive_int("ML_COMPUTE_SLOTS", max(1, cpus // threads)),
        intra_op_threads=threads,
        session_bytes=optional_positive_int(
            "MODEL_SESSION_CACHE_BYTES", int(available_memory_bytes(cgroup_root) * SESSION_SHARE_OF_MEMORY),
        ),
    )


def available_cpus(cgroup_root=CGROUP_ROOT):
    cores = len(os.sched_getaffinity(0)) if hasattr(os, "sched_getaffinity") else (os.cpu_count() or 1)
    quota = _cpu_quota(cgroup_root / "cpu.max")
    return max(1, min(cores, int(quota))) if quota is not None else cores


def available_memory_bytes(cgroup_root=CGROUP_ROOT):
    limit = _read(cgroup_root / "memory.max")
    if limit is not None and limit != "max":
        return int(limit)
    return os.sysconf("SC_PAGE_SIZE") * os.sysconf("SC_PHYS_PAGES")


def _cpu_quota(path):
    value = _read(path)
    if value is None:
        return None
    quota, _, period = value.partition(" ")
    if quota == "max" or not period:
        return None
    return int(quota) / int(period)


def _read(path):
    try:
        return path.read_text(encoding="utf-8").strip()
    except OSError:
        return None
