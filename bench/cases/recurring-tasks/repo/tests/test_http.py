import unittest

import app


class HttpTest(unittest.TestCase):
    def setUp(self):
        app.reset()

    def test_create_complete_list(self):
        status, task = app.handle("POST", "/tasks", {"title": "a", "due_date": "2026-01-10"})
        self.assertEqual(status, 201)
        status, body = app.handle("POST", f"/tasks/{task['id']}/complete")
        self.assertEqual(status, 200)
        self.assertTrue(body["task"]["done"])
        self.assertEqual(len(app.handle("GET", "/tasks")[1]["tasks"]), 1)

    def test_missing_title(self):
        self.assertEqual(app.handle("POST", "/tasks", {})[0], 400)
