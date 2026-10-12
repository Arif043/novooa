import time
from collections import defaultdict, deque
from contextlib import contextmanager
from threading import Condition


class QueueFull(Exception):
    """Der Mandant hat zu viele wartende Anfragen oder hat zu lange gewartet; die Runtime versucht es später erneut."""


class InferenceQueue:
    """
    Begrenzt, wie viele Rechnungen gleichzeitig laufen. Diese Schnittstelle bleibt, wenn später mehrere Prozesse
    eine gemeinsame Warteschlange (z. B. Redis) brauchen.
    """

    def slot(self, tenant):
        raise NotImplementedError


class _Ticket:
    __slots__ = ("tenant", "granted")

    def __init__(self, tenant):
        self.tenant = tenant
        self.granted = False


class FairInMemoryQueue(InferenceQueue):
    """
    Eine Warteschlange je Mandant, reihum bedient: Viele Anfragen eines Mandanten verdrängen die anderen nicht.
    Pro Mandant laufen höchstens `per_tenant` Rechnungen gleichzeitig, wartend höchstens `waiting_per_tenant`.
    """

    def __init__(self, slots, per_tenant=None, waiting_per_tenant=32, maximum_wait_seconds=300, clock=time.monotonic):
        self._slots = slots
        self._per_tenant = per_tenant or (slots - 1 if slots > 1 else 1)
        self._waiting_limit = waiting_per_tenant
        self._maximum_wait = maximum_wait_seconds
        self._clock = clock
        self._condition = Condition()
        self._waiting = {}
        self._order = deque()
        self._running = 0
        self._running_by_tenant = defaultdict(int)

    @contextmanager
    def slot(self, tenant):
        ticket = self._enqueue(tenant.registration)
        self._wait_for(ticket)
        try:
            yield
        finally:
            self._release(ticket.tenant)

    def _enqueue(self, tenant):
        with self._condition:
            waiting = self._waiting.get(tenant)
            if waiting is not None and len(waiting) >= self._waiting_limit:
                raise QueueFull()
            ticket = _Ticket(tenant)
            if waiting is None:
                self._waiting[tenant] = waiting = deque()
                self._order.append(tenant)
            waiting.append(ticket)
            self._dispatch()
            return ticket

    def _wait_for(self, ticket):
        deadline = self._clock() + self._maximum_wait
        with self._condition:
            while not ticket.granted:
                remaining = deadline - self._clock()
                if remaining <= 0:
                    self._withdraw(ticket)
                    raise QueueFull()
                self._condition.wait(remaining)

    def _release(self, tenant):
        with self._condition:
            self._running -= 1
            self._running_by_tenant[tenant] -= 1
            self._dispatch()

    def _dispatch(self):
        while self._running < self._slots:
            tenant = self._next_tenant()
            if tenant is None:
                break
            ticket = self._waiting[tenant].popleft()
            if not self._waiting[tenant]:
                self._forget(tenant)
            ticket.granted = True
            self._running += 1
            self._running_by_tenant[tenant] += 1
        self._condition.notify_all()

    def _next_tenant(self):
        for _ in range(len(self._order)):
            tenant = self._order[0]
            self._order.rotate(-1)
            if self._running_by_tenant[tenant] < self._per_tenant:
                return tenant
        return None

    def _withdraw(self, ticket):
        waiting = self._waiting.get(ticket.tenant)
        if waiting is not None and ticket in waiting:
            waiting.remove(ticket)
            if not waiting:
                self._forget(ticket.tenant)

    def _forget(self, tenant):
        del self._waiting[tenant]
        self._order.remove(tenant)
