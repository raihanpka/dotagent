class InMemoryTaskRepository:
    def __init__(self):
        self._tasks = {}
        self._next_id = 1

    # Stores a task and assigns its id.
    def add(self, task):
        task.id = self._next_id
        self._next_id += 1
        self._tasks[task.id] = task
        return task

    # Returns a task by id, or None.
    def get(self, task_id):
        return self._tasks.get(task_id)

    # Returns every task of a user, oldest first.
    def list_for(self, user):
        return [t for t in self._tasks.values() if t.user == user]
