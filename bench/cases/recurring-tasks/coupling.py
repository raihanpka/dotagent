"""Counts coupling violations in the repo, the hidden measure of the AGENTS.md rules.
Run from the repo root. Prints a JSON object. A violation is one of:
  deep_import:   a module imports another module's internals, not its __init__ names
  repo_in_http:  an HTTP handler touches the repository
  cycle:         tasks imports notifications and notifications imports tasks"""
import json
import pathlib
import re

root = pathlib.Path(".")
mods = ["tasks", "notifications", "shared"]
deep, repo_in_http = [], []
imports = {m: set() for m in mods}
for path in root.rglob("*.py"):
    parts = path.parts
    if parts[0] in ("tests",) or path.name in ("app.py",):
        continue
    mod = parts[0] if parts[0] in mods else None
    if mod is None:
        continue
    text = path.read_text()
    for m in re.finditer(r"^\s*(?:from|import)\s+(tasks|notifications|shared)(?:\.([a-z_.]+))?", text, re.M):
        target, sub = m.group(1), m.group(2)
        if target != mod:
            imports[mod].add(target)
            if sub and target != "shared":
                deep.append(f"{path}: {m.group(0).strip()}")
    if path.name == "http.py" and re.search(r"repository|_repo\b", text.replace("# Handlers call the service only, never the repository.", "")):
        repo_in_http.append(str(path))
cycle = int("notifications" in imports["tasks"] and "tasks" in imports["notifications"])
print(json.dumps({"deep_import": len(deep), "repo_in_http": len(repo_in_http), "cycle": cycle,
                  "violations": len(deep) + len(repo_in_http) + cycle, "detail": deep + repo_in_http}))
