#!/bin/bash
# SessionStart hook for Claude Code cloud sessions: installs npm dependencies
# (root + open-sse + packages/browser-pool workspaces) so lint, typecheck and
# tests work out of the box. Local sessions are left untouched.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}"

# Run the install only if a file that decides what gets installed changed
# since the last successful install. The hash file lives inside node_modules
# (gitignored), so it disappears together with the packages.
hashes=node_modules/.session-start.sha256
if ! sha256sum --check --status "$hashes" 2>/dev/null; then
  rm -f "$hashes"

  # `npm install` (not `npm ci`) so the cached container state is reused.
  # --no-save keeps package-lock.json untouched (npm 10 would otherwise strip the
  # `libc` fields written by newer npm). Output goes to stderr so it does not
  # land in the session context; a failure ends the script.
  npm install --no-save --no-audit --no-fund >&2

  sha256sum .claude/hooks/session-start.sh .npmrc package.json package-lock.json \
    open-sse/package.json packages/browser-pool/package.json \
    > "$hashes" 2>/dev/null || rm -f "$hashes"
fi
