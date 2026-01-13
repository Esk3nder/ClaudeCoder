#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}"

SOURCE_HOOKS="${REPO_ROOT}/.claude/hooks"
SOURCE_GUARDRAILS="${REPO_ROOT}/.claude/guardrails.md"
SOURCE_SETTINGS="${REPO_ROOT}/settings.json.example"

TARGET_CLAUDE="${HOME}/.claude"
TARGET_HOOKS="${TARGET_CLAUDE}/hooks"
TARGET_WORKFLOWS="${TARGET_HOOKS}/workflows"
TARGET_STATE="${TARGET_HOOKS}/state"
TARGET_INTERNAL_STATE="${TARGET_CLAUDE}/.state"
TARGET_SETTINGS="${TARGET_CLAUDE}/settings.json"
TARGET_GUARDRAILS="${TARGET_CLAUDE}/guardrails.md"

mkdir -p "${TARGET_HOOKS}" "${TARGET_WORKFLOWS}" "${TARGET_STATE}" "${TARGET_INTERNAL_STATE}"

cp -a "${SOURCE_HOOKS}/." "${TARGET_HOOKS}/"

if [[ ! -f "${TARGET_GUARDRAILS}" ]]; then
  cp "${SOURCE_GUARDRAILS}" "${TARGET_GUARDRAILS}"
fi

python3 - "${SOURCE_SETTINGS}" "${TARGET_SETTINGS}" <<'PY'
import json
import os
import shutil
import sys

source_path = sys.argv[1]
target_path = sys.argv[2]

with open(source_path, "r", encoding="utf-8") as handle:
    source_data = json.load(handle)

desired_hooks = source_data.get("hooks", {})

target_data = {}
if os.path.exists(target_path):
    try:
        with open(target_path, "r", encoding="utf-8") as handle:
            target_data = json.load(handle)
    except Exception:
        backup_path = f"{target_path}.bak"
        shutil.copy2(target_path, backup_path)
        target_data = {}

target_hooks = target_data.get("hooks")
if not isinstance(target_hooks, dict):
    target_hooks = {}

for hook_name, desired_entries in desired_hooks.items():
    if not isinstance(desired_entries, list):
        continue
    existing_entries = target_hooks.get(hook_name)
    if not isinstance(existing_entries, list):
        existing_entries = []
    existing_commands = {
        entry.get("command")
        for entry in existing_entries
        if isinstance(entry, dict)
    }
    for entry in desired_entries:
        if not isinstance(entry, dict):
            continue
        command = entry.get("command")
        if not isinstance(command, str) or command in existing_commands:
            continue
        existing_entries.append({"command": command})
        existing_commands.add(command)
    target_hooks[hook_name] = existing_entries

target_data["hooks"] = target_hooks

os.makedirs(os.path.dirname(target_path), exist_ok=True)
with open(target_path, "w", encoding="utf-8") as handle:
    json.dump(target_data, handle, indent=2)
    handle.write("\n")
PY

find "${TARGET_HOOKS}" -type f \( -name "*.py" -o -name "*.sh" \) -exec chmod +x {} +

echo "Installed Claude Code hooks and settings into ${TARGET_CLAUDE}."
