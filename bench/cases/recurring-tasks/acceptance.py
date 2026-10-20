"""Hidden checks for the recurring tasks case. The agent never sees this file.
Run from the repo root: python3 ../acceptance.py. Prints one line per check, exits 1 on any failure."""
import sys

sys.path.insert(0, ".")
import app  # noqa: E402
import notifications  # noqa: E402

results = []


def check(name, fn):
    try:
        fn()
        results.append((name, True))
    except Exception as err:  # noqa: BLE001
        results.append((name, False))
        print(f"  failed {name}: {type(err).__name__}: {err}")


def make(user, **body):
    body.setdefault("title", "water plants")
    return app.handle("POST", "/tasks", body, user=user)


def daily_moves_one_day():
    app.reset()
    _, t = make("a1", due_date="2026-03-31", repeat="daily")
    status, out = app.handle("POST", f"/tasks/{t['id']}/complete", user="a1")
    assert status == 200 and out["task"]["done"] is True
    assert out["next"]["due_date"] == "2026-04-01" and out["next"]["repeat"] == "daily"
    assert out["next"]["title"] == "water plants" and out["next"]["done"] is False


def weekly_moves_seven_days():
    app.reset()
    _, t = make("a2", due_date="2026-02-25", repeat="weekly")
    _, out = app.handle("POST", f"/tasks/{t['id']}/complete", user="a2")
    assert out["next"]["due_date"] == "2026-03-04"


def counted_from_due_date_not_today():
    app.reset()
    _, t = make("a3", due_date="2020-01-01", repeat="daily")
    _, out = app.handle("POST", f"/tasks/{t['id']}/complete", user="a3")
    assert out["next"]["due_date"] == "2020-01-02"


def plain_task_has_no_next():
    app.reset()
    _, t = make("a4", due_date="2026-01-01")
    _, out = app.handle("POST", f"/tasks/{t['id']}/complete", user="a4")
    assert out["next"] is None and out["task"]["done"] is True
    assert len(app.handle("GET", "/tasks", user="a4")[1]["tasks"]) == 1


def repeat_needs_due_date():
    app.reset()
    status, out = make("a5", repeat="daily")
    assert status == 400 and out == {"error": "repeat requires due_date"}


def unknown_repeat_rejected():
    app.reset()
    status, out = make("a6", due_date="2026-01-01", repeat="monthly")
    assert status == 400 and out == {"error": "repeat must be daily or weekly"}


def owner_is_notified():
    app.reset()
    _, t = make("a7", title="stand up", due_date="2026-05-09", repeat="daily")
    app.handle("POST", f"/tasks/{t['id']}/complete", user="a7")
    assert notifications.outbox_for("a7") == ["Next occurrence of stand up due 2026-05-10"]


def no_notice_without_repeat():
    app.reset()
    _, t = make("a8", due_date="2026-05-09")
    app.handle("POST", f"/tasks/{t['id']}/complete", user="a8")
    assert notifications.outbox_for("a8") == []


def existing_behaviour_kept():
    app.reset()
    assert app.handle("POST", "/tasks", {}, user="a9")[0] == 400
    assert app.handle("POST", "/tasks/99/complete", user="a9")[0] == 404
    status, t = make("a9", due_date="2026-01-01")
    assert status == 201 and t["done"] is False and t["due_date"] == "2026-01-01"


for name, fn in [(f.__name__, f) for f in (
    daily_moves_one_day, weekly_moves_seven_days, counted_from_due_date_not_today, plain_task_has_no_next,
    repeat_needs_due_date, unknown_repeat_rejected, owner_is_notified, no_notice_without_repeat,
    existing_behaviour_kept)]:
    check(name, fn)

passed = sum(ok for _, ok in results)
print(f"acceptance {passed}/{len(results)}")
sys.exit(0 if passed == len(results) else 1)
