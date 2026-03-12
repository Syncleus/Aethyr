#!/usr/bin/env bash
# Post-create hook for the VS Code Dev Container.
# Called automatically by devcontainer.json after the container is created.
# Delegates to the shared developer-setup script so that the logic lives in
# one place.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

exec bash "$REPO_ROOT/scripts/setup-dev.sh"
