#!/usr/bin/env bash
set -Eeuo pipefail

# Prepares the workspace for FTP deployment by removing files
# that should not be uploaded to the server.

echo "==> Removing development & CI-only files before FTP upload"

# ── Diagnostics: count files before cleanup ────────────────────
TOTAL_BEFORE=$(find . -not -path './.git/*' -not -name '.git' -type f | wc -l)
echo "==> [DIAG] Total files before cleanup: ${TOTAL_BEFORE}"
echo "==> [DIAG] Top-level directory sizes before cleanup:"
du -sh -- */ .[!.]* 2>/dev/null | sort -rh || true

# Remove directories not needed on the server
echo "==> Removing node_modules …"
rm -rf node_modules
echo "==> Removing tests …"
rm -rf tests
echo "==> Removing .github …"
rm -rf .github
echo "==> Removing storage/logs/*.log …"
rm -rf storage/logs/*.log

# Remove dev-only config files
echo "==> Removing development config files …"
rm -f .env .env.* .editorconfig .gitattributes .gitignore
rm -f phpunit.xml vite.config.js package.json package-lock.json
rm -f composer.lock

# ── Diagnostics: count files after cleanup ─────────────────────
TOTAL_AFTER=$(find . -not -path './.git/*' -not -name '.git' -type f | wc -l)
echo "==> [DIAG] Total files after cleanup:  ${TOTAL_AFTER}"
echo "==> [DIAG] Files removed:              $(( TOTAL_BEFORE - TOTAL_AFTER ))"
echo "==> [DIAG] Top-level directory sizes after cleanup:"
du -sh -- */ .[!.]* 2>/dev/null | sort -rh || true

echo "==> Deployment payload ready"
