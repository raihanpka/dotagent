from dataclasses import dataclass
from typing import Optional


@dataclass
class Task:
    id: int
    user: str
    title: str
    due_date: Optional[str] = None  # ISO date, YYYY-MM-DD
    done: bool = False

    # Returns the task as a plain dict for the API.
    def to_dict(self):
        return {"id": self.id, "user": self.user, "title": self.title,
                "due_date": self.due_date, "done": self.done}
