# Handlers call the service only, never the repository.


# Creates a task from a request body.
def post_task(service, user, body):
    try:
        task = service.create(user, body.get("title"), body.get("due_date"))
    except ValueError as err:
        return 400, {"error": str(err)}
    return 201, task.to_dict()


# Completes a task and returns it.
def post_complete(service, user, task_id):
    try:
        task = service.complete(user, task_id)
    except KeyError:
        return 404, {"error": "task not found"}
    return 200, {"task": task.to_dict()}


# Lists the tasks of a user.
def get_tasks(service, user):
    return 200, {"tasks": [t.to_dict() for t in service.list(user)]}
