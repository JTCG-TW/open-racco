#!/bin/sh
# cd to the plugin directory so bun finds the correct package.json
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PLUGIN_DIR"
# Find bun from common install locations
for BUN in \
  "$HOME/.bun/bin/bun" \
  "/opt/homebrew/bin/bun" \
  "/usr/local/bin/bun" \
  "$(command -v bun 2>/dev/null)"
do
  if [ -x "$BUN" ]; then
    exec "$BUN" run --shell=bun --silent start
  fi
done

echo "slack channel: bun not found. Install bun: https://bun.sh" >&2
exit 1
