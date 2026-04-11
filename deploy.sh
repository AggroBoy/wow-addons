#!/bin/bash
set -euo pipefail

ADDONS_DIR="/Volumes/AddOns"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check the share is mounted
if [ ! -d "$ADDONS_DIR" ]; then
    echo "Error: $ADDONS_DIR is not available. Is the share mounted?"
    exit 1
fi

# If addon names are passed as arguments, deploy only those; otherwise deploy all
if [ $# -gt 0 ]; then
    addons=("$@")
else
    addons=()
    for dir in "$REPO_DIR"/*/; do
        name="$(basename "$dir")"
        # Skip hidden dirs and anything that isn't an addon (no .toc file)
        [ -f "$dir/$name.toc" ] || continue
        addons+=("$name")
    done
fi

if [ ${#addons[@]} -eq 0 ]; then
    echo "No addons found to deploy."
    exit 0
fi

for addon in "${addons[@]}"; do
    src="$REPO_DIR/$addon"
    if [ ! -d "$src" ]; then
        echo "Error: $addon not found in repo"
        exit 1
    fi
    echo "Deploying $addon..."
    rsync -av --delete --exclude='.git' "$src/" "$ADDONS_DIR/$addon/"
done

echo "Done."
