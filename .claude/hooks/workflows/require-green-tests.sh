#!/usr/bin/env bash
set -euo pipefail

emit_json() {
  local decision="$1"
  local reason="$2"
  python3 -c "import json; print(json.dumps({'decision': '$decision', 'reason': '$reason'}))"
}

if [[ "${WORKFLOWS_SKIP_TESTS:-}" == "true" ]]; then
  emit_json "approve" "require-green-tests: skipped (WORKFLOWS_SKIP_TESTS=true)"
  exit 0
fi

has_npm_test() {
  [[ -f package.json ]] || return 1
  python3 - <<'PY'
import json
import sys

try:
    with open("package.json", "r", encoding="utf-8") as handle:
        data = json.load(handle)
except Exception:
    sys.exit(1)

scripts = data.get("scripts", {})
if isinstance(scripts, dict) and isinstance(scripts.get("test"), str):
    sys.exit(0)
sys.exit(1)
PY
}

has_pytest() {
  if [[ -f pytest.ini || -f tox.ini ]]; then
    return 0
  fi
  if [[ -f setup.cfg ]] && grep -q "^\[tool:pytest\]" setup.cfg; then
    return 0
  fi
  if [[ -f pyproject.toml ]] && grep -q "^\[tool\.pytest\.ini_options\]" pyproject.toml; then
    return 0
  fi
  if [[ -d tests ]]; then
    if find tests -type f \( -name "test*.py" -o -name "*_test.py" \) -print -quit | grep -q .; then
      return 0
    fi
  fi
  return 1
}

has_cargo() {
  [[ -f Cargo.toml ]]
}

has_go() {
  [[ -f go.mod ]] || [[ -f go.sum ]] || find . -type f -name "*_test.go" -print -quit | grep -q .
}

TEST_CMD=()
TEST_LABEL=""
if has_npm_test; then
  TEST_CMD=(npm test)
  TEST_LABEL="npm test"
elif has_pytest; then
  TEST_CMD=(pytest)
  TEST_LABEL="pytest"
elif has_cargo; then
  TEST_CMD=(cargo test)
  TEST_LABEL="cargo test"
elif has_go; then
  TEST_CMD=(go test ./...)
  TEST_LABEL="go test"
fi

if [[ ${#TEST_CMD[@]} -eq 0 ]]; then
  emit_json "approve" "require-green-tests: no test infrastructure detected"
  exit 0
fi

echo "Running tests: ${TEST_LABEL}" >&2
if ! "${TEST_CMD[@]}" >&2; then
  emit_json "block" "require-green-tests: tests failed"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
STATE_DIR="${CLAUDE_DIR}/.state"
STATE_FILE="${STATE_DIR}/last_tests.env"
mkdir -p "${STATE_DIR}"

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
temp_file="${STATE_FILE}.tmp"
{
  echo "LAST_TESTS_STATUS=green"
  echo "LAST_TESTS_COMMAND=\"${TEST_LABEL}\""
  echo "LAST_TESTS_RAN_AT=\"${timestamp}\""
} > "${temp_file}"
mv "${temp_file}" "${STATE_FILE}"

emit_json "approve" "require-green-tests: tests passed"
