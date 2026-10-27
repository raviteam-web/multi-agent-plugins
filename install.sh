#!/usr/bin/env bash
# Manual install of the delivery-crew plugin for VS Code / Claude Code panel users
# who can't run `/plugin marketplace add` + `/plugin install`.
#
# Copies agents/ and commands/ straight into the target project's .claude/ folder
# (namespaced under delivery-crew/) and writes a version stamp for `install.sh --update`.
#
# Usage: ./install.sh <path-to-project>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR/plugins/delivery-crew"
VERSION="$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$PLUGIN_DIR/.claude-plugin/plugin.json" | sed -E 's/.*"([^"]+)"$/\1/')"

TARGET="${1:-}"
if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
  echo "Usage: $0 <path-to-project>" >&2
  exit 1
fi

DEST_AGENTS="$TARGET/.claude/agents/delivery-crew"
DEST_COMMANDS="$TARGET/.claude/commands/delivery-crew"

mkdir -p "$DEST_AGENTS" "$DEST_COMMANDS"
cp -f "$PLUGIN_DIR"/agents/*.md "$DEST_AGENTS/"
cp -f "$PLUGIN_DIR"/commands/*.md "$DEST_COMMANDS/"

echo "$VERSION" > "$TARGET/.claude/delivery-crew.version"

echo "Installed delivery-crew v$VERSION into $TARGET/.claude/"
echo "Next: open $TARGET in Claude Code / the VS Code panel, run /help to see the installed"
echo "command names (all prefixed ma-: ma-init, ma-plan, ma-deliver, ma-po-new, ma-po-edit, ma-deploy,"
echo "ma-document), then start with ma-init."
echo "To update later: pull the latest plugin repo and re-run this script."
