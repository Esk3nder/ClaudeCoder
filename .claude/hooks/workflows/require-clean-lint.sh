#!/usr/bin/env bash
set -euo pipefail

if [[ "${WORKFLOWS_SKIP_LINT:-}" == "true" ]]; then
  echo "Skipping lint (WORKFLOWS_SKIP_LINT=true)."
  exit 0
fi

has_npm_lint() {
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
if isinstance(scripts, dict) and isinstance(scripts.get("lint"), str):
    sys.exit(0)
sys.exit(1)
PY
}

has_ruff() {
  if [[ -f ruff.toml ]]; then
    return 0
  fi
  if [[ -f pyproject.toml ]] && grep -Eq "^\[tool\.ruff(\.lint)?\]" pyproject.toml; then
    return 0
  fi
  return 1
}

has_eslint() {
  if [[ -f .eslintrc || -f .eslintrc.js || -f .eslintrc.cjs || -f .eslintrc.json || -f .eslintrc.yaml || -f .eslintrc.yml ]]; then
    return 0
  fi
  [[ -f package.json ]] || return 1
  python3 - <<'PY'
import json
import sys

try:
    with open("package.json", "r", encoding="utf-8") as handle:
        data = json.load(handle)
except Exception:
    sys.exit(1)

if isinstance(data.get("eslintConfig"), dict):
    sys.exit(0)

for dep_key in ("dependencies", "devDependencies", "peerDependencies", "optionalDependencies"):
    deps = data.get(dep_key, {})
    if isinstance(deps, dict) and "eslint" in deps:
        sys.exit(0)

sys.exit(1)
PY
}

has_cargo() {
  [[ -f Cargo.toml ]]
}

LINT_CMD=()
LINT_LABEL=""
if has_npm_lint; then
  LINT_CMD=(npm run lint)
  LINT_LABEL="npm run lint"
elif has_ruff; then
  LINT_CMD=(ruff check .)
  LINT_LABEL="ruff"
elif has_eslint; then
  LINT_CMD=(npx --no-install eslint .)
  LINT_LABEL="eslint"
elif has_cargo; then
  LINT_CMD=(cargo clippy)
  LINT_LABEL="cargo clippy"
fi

if [[ ${#LINT_CMD[@]} -eq 0 ]]; then
  echo "No lint infrastructure detected; skipping."
  exit 0
fi

echo "Running lint: ${LINT_LABEL}"
if ! "${LINT_CMD[@]}"; then
  echo "Lint failed."
  exit 1
fi

echo "Lint passed."
