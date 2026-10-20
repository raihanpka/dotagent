Add recurring tasks to taskboard.

Requirements from product, pasted as received:

1. A task can have a repeat of `daily` or `weekly`. The default is no repeat.
2. When a repeating task is completed, mark it done and create the next one with the same title and the same repeat. Move the due date forward by 1 day (daily) or 7 days (weekly), counted from the previous due date, not from the day it was completed.
3. A repeating task must have a due date. Creating one without it is rejected with the message `repeat requires due_date`. An unknown repeat value is rejected with `repeat must be daily or weekly`.
4. API: `POST /tasks` accepts `repeat`. `POST /tasks/{id}/complete` returns `{"task": ..., "next": ...}` where `next` is the new task, or null when nothing repeats. A 400 carries `{"error": message}`.
5. When a next task is created, notify its owner with the message `Next occurrence of <title> due <YYYY-MM-DD>`.
6. Nothing that works today may change. Add tests and update the README.
