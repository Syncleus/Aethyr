#!/bin/sh
set -e

cd /app

# Verify that `/app` is mounted as an *external* Docker volume before attempting to
# perform the potentially time-consuming `pip install`.  We detect a volume mount
# by checking for an explicit `/app` entry in `/proc/self/mountinfo` which lists
# all mount points visible to the current process.
if [ -f /proc/self/mountinfo ] && grep -q '/_data[[:space:]]/app[[:space:]]' /proc/self/mountinfo; then
    # `/app` is *not* mounted as a volume.  Skip installation to avoid polluting
    # the image and to respect the caller's intent.
    echo "Skipping requirements installation because /app is not a mounted volume." >&2
elif [ -f requirements.txt ]; then 
    # `/app` **is** a separate mount → proceed with installation.
    pyenv local 3.10.17
    python -m pip install --no-cache-dir -r requirements.txt
    pyenv local 3.11.12
    python -m pip install --no-cache-dir -r requirements.txt
    pyenv local 3.12.10
    python -m pip install --no-cache-dir -r requirements.txt
    pyenv local 3.13.3
    python -m pip install --no-cache-dir -r requirements.txt
fi
