#!/usr/bin/env python3
"""Deterministic guards for the dotagent: commit style, PR title, merge level, em dash, big reads.

Reads one hook event as JSON on stdin. Exit 2 with a reason on stderr blocks the tool call.
Settings come from the plugin options: CLAUDE_PLUGIN_OPTION_SCALE, _MERGE, _EM_DASH.
"""
import json
import os
import re
import shlex
import sys

# Top of the usual file size range (ESLint recommends 100 to 500, Clean Code says 500 at most): see docs/PRACTICES.md.
READ_LINES = 500
EM_DASH = chr(0x2014)
EMOJI = re.compile("[" + chr(0x1F300) + "-" + chr(0x1FAFF) + chr(0x2600) + "-" + chr(0x27BF) + chr(0x1F000) + "-" + chr(0x1F2FF) + "]")
TYPES = "feat|fix|hotfix|docs|style|refactor|test|chore|perf|revert|ci|build"
COMMIT = re.compile(rf"^({TYPES})\([a-zA-Z0-9_.-]+\): \S")
TITLE = re.compile(rf"^({TYPES})(\([a-zA-Z0-9_.-]+\))?: \S")
MERGE_SUBJECT = re.compile(r"\(#\d+\)$")
SKIP_READ = re.compile(
    r"(\.(g|freezed|pb)\.\w+$|\.(lock|min\.js|min\.css|png|jpe?g|gif|webp|pdf|ipynb|svg)$|"
    r"(^|/)(node_modules|dist|build|generated|vendor|\.dart_tool)/|package-lock\.json$)"
)


def opt(name, default):
    return os.environ.get("CLAUDE_PLUGIN_OPTION_" + name, default) or default


def block(reason):
    # Blocks the tool call and tells the agent what to do instead.
    print("dotagent: " + reason, file=sys.stderr)
    sys.exit(2)


def flag_values(tokens, short, long):
    # Collects the value of every `-x value`, `-xvalue`, `--long value` and `--long=value` flag.
    values = []
    for i, tok in enumerate(tokens):
        if tok == long or (short and tok == short):
            if i + 1 < len(tokens):
                values.append(tokens[i + 1])
        elif tok.startswith(long + "="):
            values.append(tok.split("=", 1)[1])
    return values


def commits_in(tokens):
    # Splits a shell command into the argument lists of each `git commit`.
    found = []
    for i in range(len(tokens) - 1):
        if tokens[i] == "git" and tokens[i + 1] == "commit":
            end = len(tokens)
            for j in range(i + 2, len(tokens)):
                if tokens[j] in ("&&", "||", ";", "|"):
                    end = j
                    break
            found.append(tokens[i + 2 : end])
    return found


def no_emoji(text, where):
    # Refuses an emoji in commit and PR text, unless the user allows emoji.
    if opt("EMOJI", "block") != "allow" and EMOJI.search(text):
        block(f"no emoji in {where}.")


def check_commit(args):
    # A commit message is one conventional line, no trailer, no em dash.
    messages = flag_values(args, "-m", "--message")
    for tok in args:
        if re.fullmatch(r"-[a-zA-Z]*m", tok) and tok != "-m":
            messages += flag_values(args, tok, "--none")
    if not messages:
        return
    if len(messages) > 1:
        block("a commit message is a single line. Use one -m and put the detail in the PR.")
    msg = messages[0]
    if "\n" in msg or "<<" in msg:
        block("a commit message is a single line, no body and no heredoc.")
    if re.search(r"co-authored-by", msg, re.I):
        block("no Co-Authored-By trailer in commit messages.")
    if EM_DASH in msg:
        block("no em dash in commit messages. Use a comma, period, or parentheses.")
    no_emoji(msg, "commit messages")
    if not COMMIT.match(msg):
        block("commit message must look like `type(scope): summary` with a scope, for example `fix(auth): stop token reuse`.")


def check_pr_create(tokens):
    # A PR title follows the commit format and no text carries an em dash.
    for title in flag_values(tokens, "-t", "--title"):
        if not TITLE.match(title):
            block("PR title must look like `type: summary` or `type(scope): summary`.")
    for text in flag_values(tokens, "-t", "--title") + flag_values(tokens, "-b", "--body"):
        if EM_DASH in text:
            block("no em dash in PR text. Use a comma, period, or parentheses.")
        no_emoji(text, "PR text, drop any generated-by line")


def check_pr_merge(tokens):
    # Merging obeys the configured level and the `<title> (#N)` merge subject.
    if opt("MERGE", "off") == "off":
        block("merge level is off. Leave the merge to the user.")
    for subject in flag_values(tokens, "-t", "--subject"):
        if not MERGE_SUBJECT.search(subject):
            block("merge subject must end with the PR number, like `fix: a (#5)`.")


def on_bash(command):
    # Routes a Bash command to the commit, PR create, or PR merge check.
    try:
        tokens = shlex.split(command, posix=True)
    except ValueError:
        tokens = command.split()
    for args in commits_in(tokens):
        check_commit(args)
    for i in range(len(tokens) - 2):
        if tokens[i] == "gh" and tokens[i + 1] == "pr":
            if tokens[i + 2] == "create":
                check_pr_create(tokens[i + 3 :])
            elif tokens[i + 2] == "merge":
                check_pr_merge(tokens[i + 3 :])


def on_write(tool_input):
    # Refuses an em dash in text the agent writes, unless the user allows it.
    if opt("EM_DASH", "block") == "allow":
        return
    text = tool_input.get("content") or tool_input.get("new_string") or ""
    if EM_DASH in text:
        block("no em dash in files. Use a comma, period, or parentheses.")


def on_read(tool_input):
    # Blocks a whole read of a source file over the read limit, a range read passes.
    path = tool_input.get("file_path", "")
    if tool_input.get("offset") or tool_input.get("limit") or SKIP_READ.search(path):
        return
    try:
        with open(path, "rb") as handle:
            lines = sum(1 for _ in handle)
    except OSError:
        return
    if lines > READ_LINES:
        block(
            f"{path} has {lines} lines (whole read limit {READ_LINES}). Grep for the symbol, then Read with "
            "offset and limit, or ask a subagent to summarize it."
        )


def main():
    # Dispatches on the hook event and tool name.
    try:
        event = json.load(sys.stdin)
    except json.JSONDecodeError:
        return
    if event.get("hook_event_name") == "SessionStart":
        print(
            f"[dotagent] scale={opt('SCALE', 'medium')} merge={opt('MERGE', 'off')} "
            f"read-limit={READ_LINES} style={opt('STYLE_SKILLS', 'none')}"
        )
        return
    tool = event.get("tool_name")
    tool_input = event.get("tool_input") or {}
    if tool == "Bash":
        on_bash(tool_input.get("command", ""))
    elif tool in ("Write", "Edit"):
        on_write(tool_input)
    elif tool == "Read":
        on_read(tool_input)


if __name__ == "__main__":
    main()
