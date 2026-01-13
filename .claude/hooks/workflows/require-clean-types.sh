#!/usr/bin/env bash
set -euo pipefail

if [[ "${WORKFLOWS_SKIP_TYPES:-}" == "true" ]]; then
  echo "Skipping types (WORKFLOWS_SKIP_TYPES=true)."
  exit 0
fi

has_tsc() {
  if [[ -f tsconfig.json ]]; then
    return 0
  fi
  if find . -maxdepth 2 -type f -name "tsconfig*.json" -print -quit | grep -q .; then
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

scripts = data.get("scripts", {})
if isinstance(scripts, dict) and isinstance(scripts.get("tsc"), str):
    sys.exit(0)

for dep_key in ("dependencies", "devDependencies", "peerDependencies", "optionalDependencies"):
    deps = data.get(dep_key, {})
    if isinstance(deps, dict) and "typescript" in deps:
        sys.exit(0)

sys.exit(1)
PY
}

has_pyright() {
  if [[ -f pyrightconfig.json ]]; then
    return 0
  fi
  if [[ -f pyproject.toml ]] && grep -q "^\[tool\.pyright\]" pyproject.toml; then
    return 0
  fi
  return 1
}

has_mypy() {
  if [[ -f mypy.ini || -f .mypy.ini ]]; then
    return 0
  fi
  if [[ -f setup.cfg ]] && grep -q "^\[mypy\]" setup.cfg; then
    return 0
  fi
  if [[ -f pyproject.toml ]] && grep -q "^\[tool\.mypy\]" pyproject.toml; then
    return 0
  fi
  return 1
}

TYPE_CMD=()
TYPE_LABEL=""
if has_tsc; then
  TYPE_CMD=(npx --no-install tsc --noEmit)
  TYPE_LABEL="tsc --noEmit"
elif has_pyright; then
  TYPE_CMD=(pyright)
  TYPE_LABEL="pyright"
elif has_mypy; then
  TYPE_CMD=(mypy .)
  TYPE_LABEL="mypy"
fi

if [[ ${#TYPE_CMD[@]} -eq 0 ]]; then
  echo "No type infrastructure detected; skipping."
  exit 0
fi

echo "Running types: ${TYPE_LABEL}"
if ! "${TYPE_CMD[@]}"; then
  echo "Type check failed."
  exit 1
fi

echo "Types passed."
