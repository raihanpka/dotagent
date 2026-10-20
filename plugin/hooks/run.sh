#!/bin/sh
# Runs guard.py with whichever Python 3 exists: python3 on macOS and Linux, python or py on Windows.
here="$(dirname "$0")"
for py in python3 python py; do
  if "$py" -c "import sys; sys.exit(sys.version_info < (3, 8))" >/dev/null 2>&1; then
    exec "$py" "$here/guard.py" "$@"
  fi
done
echo "dotagent: Python 3.8 or newer not found (tried python3, python, py), the guards are off." >&2
exit 1
