import unittest

from tasks import TaskService


class TaskServiceTest(unittest.TestCase):
    def test_create_and_complete(self):
        svc = TaskService()
        task = svc.create("u1", "write report", "2026-01-10")
        self.assertFalse(task.done)
        self.assertTrue(svc.complete("u1", task.id).done)

    def test_title_required(self):
        with self.assertRaises(ValueError):
            TaskService().create("u1", "  ")

    def test_other_user_cannot_complete(self):
        svc = TaskService()
        task = svc.create("u1", "a")
        with self.assertRaises(KeyError):
            svc.complete("u2", task.id)
