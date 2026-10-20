import re

from tasks import TaskService
from tasks import http as tasks_http

_service = TaskService()


# Replaces the service with a fresh one, used by tests.
def reset():
    global _service
    _service = TaskService()


# Routes a request to a handler and returns (status, json dict).
def handle(method, path, body=None, user="u1"):
    body = body or {}
    if method == "POST" and path == "/tasks":
        return tasks_http.post_task(_service, user, body)
    if method == "GET" and path == "/tasks":
        return tasks_http.get_tasks(_service, user)
    match = re.fullmatch(r"/tasks/(\d+)/complete", path)
    if method == "POST" and match:
        return tasks_http.post_complete(_service, user, int(match.group(1)))
    return 404, {"error": "not found"}
