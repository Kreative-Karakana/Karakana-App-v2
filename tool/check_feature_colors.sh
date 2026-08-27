#!/usr/bin/env bash
set -euo pipefail

# Fail only when a change introduces a new raw hex colour in a feature file.
# Existing legacy literals are tracked separately and can be migrated in
# reviewed batches without blocking unrelated pull requests.
base_ref="${1:-origin/main}"
range="${base_ref}...HEAD"

added_literals=$(git diff --unified=0 "$range" -- 'lib/features/**/*.dart' 'lib/features/*.dart' \
  | sed -n 's/^+[^+].*Color(0x[0-9A-Fa-f]\{8\}).*/&/p' || true)

if [[ -n "$added_literals" ]]; then
  echo "Raw feature color literals were added. Use AppColors (or document a fixed-artwork exception):"
  echo "$added_literals"
  exit 1
fi

echo "No new raw hex color literals found in lib/features."
