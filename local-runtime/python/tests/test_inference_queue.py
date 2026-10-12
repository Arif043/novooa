import threading
import unittest

import ml_test_support  # noqa: F401  (setzt den Paketpfad)
from novooa_ml.inference_queue import FairInMemoryQueue, QueueFull
from novooa_ml.tenants.tenant import Tenant

A, B = Tenant("a", "a"), Tenant("b", "b")


class FairInMemoryQueueTest(unittest.TestCase):
    def test_serves_waiting_tenants_in_turn(self):
        queue = FairInMemoryQueue(slots=1, per_tenant=1)
        order = []
        blocker = queue.slot(A)
        blocker.__enter__()
        threads = [self.waiting(queue, tenant, order) for tenant in [A, A, B]]

        blocker.__exit__(None, None, None)
        for thread in threads:
            thread.join(timeout=5)

        self.assertEqual(order, ["a", "b", "a"])

    def test_limits_concurrent_work_per_tenant(self):
        queue = FairInMemoryQueue(slots=2, per_tenant=1, maximum_wait_seconds=0.05)
        with queue.slot(A):
            with self.assertRaises(QueueFull):
                with queue.slot(A):
                    pass
            with queue.slot(B):
                pass

    def test_rejects_immediately_when_too_many_requests_wait(self):
        queue = FairInMemoryQueue(slots=1, waiting_per_tenant=1, maximum_wait_seconds=5)
        blocker = queue.slot(A)
        blocker.__enter__()
        waiting = self.waiting(queue, A, [])

        with self.assertRaises(QueueFull):
            with queue.slot(A):
                pass
        blocker.__exit__(None, None, None)
        waiting.join(timeout=5)

    def waiting(self, queue, tenant, order):
        """Startet eine wartende Anfrage und kehrt erst zurück, wenn sie in der Warteschlange steht."""
        before = waiting_count(queue)

        def work():
            with queue.slot(tenant):
                order.append(tenant.id)

        thread = threading.Thread(target=work)
        thread.start()
        self.wait_until(lambda: waiting_count(queue) == before + 1)
        return thread

    def wait_until(self, condition):
        event = threading.Event()
        for _ in range(500):
            if condition():
                return
            event.wait(0.002)
        self.fail("Bedingung nicht erreicht.")


def waiting_count(queue):
    return sum(len(tickets) for tickets in queue._waiting.values())


if __name__ == "__main__":
    unittest.main()
