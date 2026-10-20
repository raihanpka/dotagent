"""Public interface of the notifications module: notify and outbox_for."""
from .outbox import notify, outbox_for

__all__ = ["notify", "outbox_for"]
