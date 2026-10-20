"""Public interface of the tasks module: Task and TaskService."""
from .models import Task
from .service import TaskService

__all__ = ["Task", "TaskService"]
