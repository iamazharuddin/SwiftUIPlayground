#!/usr/bin/env bash
# Materialize base64-encoded secrets into files the toolchain expects at runtime.
# Called early in beta/release jobs. Teaching reference: docs/cicd/part-10-secrets.md
#
# Required env (from GitHub Secrets):
#   ASC_KEY_ID   - App Store Connect API key id (also names the file)
#   ASC_KEY_P8   - base64 of the AuthKey_XXXX.p8 file
set -euo pipefail

: "${ASC_KEY_ID:?ASC_KEY_ID is required}"
: "${ASC_KEY_P8:?ASC_KEY_P8 is required}"

KEYS_DIR="$HOME/private_keys"
mkdir -p "$KEYS_DIR"

# Decode the App Store Connect API key into the conventional location.
echo "$ASC_KEY_P8" | base64 --decode > "$KEYS_DIR/AuthKey_${ASC_KEY_ID}.p8"
chmod 600 "$KEYS_DIR/AuthKey_${ASC_KEY_ID}.p8"

# Confirm WITHOUT leaking the secret (print only a fingerprint).
echo "Wrote AuthKey_${ASC_KEY_ID}.p8 (${#ASC_KEY_P8} b64 chars) to $KEYS_DIR"
