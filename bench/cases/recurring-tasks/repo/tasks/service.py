from .models import Task
from .repository import InMemoryTaskRepository


class TaskService:
    def __init__(self, repository=None):
        self._repo = repository or InMemoryTaskRepository()

    # Creates a task for a user.
    def create(self, user, title, due_date=None):
        if not title or not title.strip():
            raise ValueError("title is required")
        return self._repo.add(Task(id=0, user=user, title=title.strip(), due_date=due_date))

    # Marks a task done and returns it.
    def complete(self, user, task_id):
        task = self._repo.get(task_id)
        if task is None or task.user != user:
            raise KeyError("task not found")
        task.done = True
        return task

    # Lists the tasks of a user.
    def list(self, user):
        return self._repo.list_for(user)
