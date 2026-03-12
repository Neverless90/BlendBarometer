#!/usr/bin/env bash
# Tests for scripts/prepare-deploy.sh
# Runs in an isolated temporary directory so it never touches the real workspace.
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREPARE_SCRIPT="${SCRIPT_DIR}/../../scripts/prepare-deploy.sh"

PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; (( PASS++ )) || true; }
fail() { echo "  [FAIL] $1"; (( FAIL++ )) || true; }

# ── Helper: set up a minimal fake workspace ─────────────────────
setup_workspace() {
  local dir
  dir="$(mktemp -d)"

  # Directories that SHOULD be removed
  mkdir -p "${dir}/node_modules/some-pkg"
  touch    "${dir}/node_modules/some-pkg/index.js"
  mkdir -p "${dir}/tests/Unit"
  touch    "${dir}/tests/Unit/ExampleTest.php"
  mkdir -p "${dir}/.github/workflows"
  touch    "${dir}/.github/workflows/deploy.yml"
  mkdir -p "${dir}/storage/logs"
  touch    "${dir}/storage/logs/laravel.log"

  # Files that SHOULD be removed
  touch "${dir}/.env"
  touch "${dir}/.env.example"
  touch "${dir}/.editorconfig"
  touch "${dir}/.gitattributes"
  touch "${dir}/.gitignore"
  touch "${dir}/phpunit.xml"
  touch "${dir}/vite.config.js"
  touch "${dir}/package.json"
  touch "${dir}/package-lock.json"
  touch "${dir}/composer.lock"

  # Files that should SURVIVE
  mkdir -p "${dir}/app/Http/Controllers"
  touch    "${dir}/app/Http/Controllers/HomeController.php"
  mkdir -p "${dir}/public"
  touch    "${dir}/public/index.php"
  touch    "${dir}/artisan"
  touch    "${dir}/composer.json"
  touch    "${dir}/README.md"

  echo "${dir}"
}

# ── Test 1: script exits successfully ───────────────────────────
echo "--- Test 1: script exits with code 0"
WORKSPACE="$(setup_workspace)"
(
  cd "${WORKSPACE}"
  bash "${PREPARE_SCRIPT}" > /dev/null 2>&1
)
if [ $? -eq 0 ]; then
  pass "script exits with code 0"
else
  fail "script exited with non-zero code"
fi
rm -rf "${WORKSPACE}"

# ── Test 2: dev directories are removed ─────────────────────────
echo "--- Test 2: dev directories are removed after cleanup"
WORKSPACE="$(setup_workspace)"
(
  cd "${WORKSPACE}"
  bash "${PREPARE_SCRIPT}" > /dev/null 2>&1
)
for dir in node_modules tests .github; do
  if [ ! -e "${WORKSPACE}/${dir}" ]; then
    pass "'${dir}' was removed"
  else
    fail "'${dir}' still exists after cleanup"
  fi
done
rm -rf "${WORKSPACE}"

# ── Test 3: dev-only files are removed ──────────────────────────
echo "--- Test 3: dev-only files are removed after cleanup"
WORKSPACE="$(setup_workspace)"
(
  cd "${WORKSPACE}"
  bash "${PREPARE_SCRIPT}" > /dev/null 2>&1
)
for f in .env .env.example .editorconfig .gitattributes .gitignore phpunit.xml vite.config.js package.json package-lock.json composer.lock; do
  if [ ! -e "${WORKSPACE}/${f}" ]; then
    pass "'${f}' was removed"
  else
    fail "'${f}' still exists after cleanup"
  fi
done
rm -rf "${WORKSPACE}"

# ── Test 4: application files survive ───────────────────────────
echo "--- Test 4: application files survive cleanup"
WORKSPACE="$(setup_workspace)"
(
  cd "${WORKSPACE}"
  bash "${PREPARE_SCRIPT}" > /dev/null 2>&1
)
for f in app/Http/Controllers/HomeController.php public/index.php artisan composer.json; do
  if [ -e "${WORKSPACE}/${f}" ]; then
    pass "'${f}' still present after cleanup"
  else
    fail "'${f}' was unexpectedly removed"
  fi
done
rm -rf "${WORKSPACE}"

# ── Test 5: diagnostic output mentions file counts ──────────────
echo "--- Test 5: diagnostic output mentions file counts"
WORKSPACE="$(setup_workspace)"
OUTPUT="$(
  cd "${WORKSPACE}"
  bash "${PREPARE_SCRIPT}" 2>&1
)"
rm -rf "${WORKSPACE}"

if echo "${OUTPUT}" | grep -q "\[DIAG\] Total files before cleanup:"; then
  pass "output contains 'Total files before cleanup' diagnostic"
else
  fail "output missing 'Total files before cleanup' diagnostic"
fi

if echo "${OUTPUT}" | grep -q "\[DIAG\] Total files after cleanup:"; then
  pass "output contains 'Total files after cleanup' diagnostic"
else
  fail "output missing 'Total files after cleanup' diagnostic"
fi

if echo "${OUTPUT}" | grep -q "\[DIAG\] Files removed:"; then
  pass "output contains 'Files removed' diagnostic"
else
  fail "output missing 'Files removed' diagnostic"
fi

# ── Test 6: before-count is greater than after-count ────────────
echo "--- Test 6: before-count is strictly greater than after-count"
WORKSPACE="$(setup_workspace)"
OUTPUT="$(
  cd "${WORKSPACE}"
  bash "${PREPARE_SCRIPT}" 2>&1
)"
rm -rf "${WORKSPACE}"

BEFORE=$(echo "${OUTPUT}" | grep "Total files before cleanup:" | grep -o '[0-9]\+$')
AFTER=$(echo  "${OUTPUT}" | grep "Total files after cleanup:"  | grep -o '[0-9]\+$')

if [ -n "${BEFORE}" ] && [ -n "${AFTER}" ] && [ "${BEFORE}" -gt "${AFTER}" ]; then
  pass "before-count (${BEFORE}) > after-count (${AFTER})"
else
  fail "expected before-count (${BEFORE:-?}) > after-count (${AFTER:-?})"
fi

# ── Summary ─────────────────────────────────────────────────────
echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
if [ "${FAIL}" -gt 0 ]; then
  exit 1
fi
