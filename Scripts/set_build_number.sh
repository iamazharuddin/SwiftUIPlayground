#!/usr/bin/env bash
# Set CFBundleVersion (build number) deterministically from git history.
# Requires a full clone (checkout with fetch-depth: 0).
# Teaching reference: docs/cicd/part-20-versioning.md
set -euo pipefail

# Commit count is strictly increasing as history grows -> a valid, monotonic build number.
BUILD_NUMBER="$(git rev-list --count HEAD)"

# agvtool writes CFBundleVersion across all targets in the project.
if command -v agvtool >/dev/null 2>&1; then
  agvtool new-version -all "$BUILD_NUMBER" >/dev/null
fi

echo "Set build number to $BUILD_NUMBER"

# Expose to later workflow steps (Part 4): needs.<job>.outputs.build_number
echo "build_number=$BUILD_NUMBER" >> "${GITHUB_OUTPUT:-/dev/null}"
