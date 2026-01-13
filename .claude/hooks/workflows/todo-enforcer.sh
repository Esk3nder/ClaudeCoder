#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"
transcript_path="$(
  python3 - <<'PY' <<<"${payload}"
import json
import sys

raw = sys.stdin.read()
if not raw.strip():
    sys.exit(0)
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    sys.exit(0)

path = data.get("transcript_path") or data.get("transcriptPath") or ""
if isinstance(path, str):
    sys.stdout.write(path)
PY
)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
STATE_DIR="${CLAUDE_DIR}/.state"
STATE_FILE="${STATE_DIR}/todo-enforcer.state"

block_count=0
if [[ -f "${STATE_FILE}" ]]; then
  read -r block_count < "${STATE_FILE}" || true
fi
if ! [[ "${block_count}" =~ ^[0-9]+$ ]]; then
  block_count=0
fi

decision="approve"
reason="todo-enforcer: no pending todos"

if [[ -z "${transcript_path}" || ! -f "${transcript_path}" ]]; then
  decision="approve"
  reason="todo-enforcer: no transcript available"
  block_count=0
else
  counts="$(
    python3 - "${transcript_path}" <<'PY'
import json
import os
import re
import sys

path = sys.argv[1]
statuses = []

def record_status(status):
    if isinstance(status, str):
        statuses.append(status)

def inspect_obj(obj):
    if isinstance(obj, dict):
        tool_name = None
        for key in ("tool_name", "toolName", "name", "tool"):
            value = obj.get(key)
            if isinstance(value, str):
                tool_name = value
                break
            if isinstance(value, dict):
                nested = value.get("name")
                if isinstance(nested, str):
                    tool_name = nested
                    break
        if tool_name == "TodoWrite":
            tool_input = None
            for key in ("tool_input", "toolInput", "input"):
                if key in obj:
                    tool_input = obj.get(key)
                    break
            if isinstance(tool_input, dict):
                todos = tool_input.get("todos")
                if isinstance(todos, list):
                    for todo in todos:
                        if isinstance(todo, dict):
                            record_status(todo.get("status"))
        for value in obj.values():
            inspect_obj(value)
    elif isinstance(obj, list):
        for item in obj:
            inspect_obj(item)

def parse_json_blob(text):
    try:
        data = json.loads(text)
    except Exception:
        return False
    inspect_obj(data)
    return True

if not os.path.exists(path):
    print("0 0 0")
    sys.exit(0)

with open(path, "r", encoding="utf-8") as handle:
    content = handle.read()

parsed = parse_json_blob(content)
if not parsed:
    found = False
    for line in content.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            data = json.loads(line)
        except Exception:
            continue
        found = True
        inspect_obj(data)
    if not found and "TodoWrite" in content:
        for match in re.finditer(r'"status"\\s*:\\s*"([^"]+)"', content):
            statuses.append(match.group(1))

pending = sum(1 for status in statuses if status == "pending")
in_progress = sum(1 for status in statuses if status == "in_progress")
total = len(statuses)
print(f"{pending} {in_progress} {total}")
PY
  )"
  read -r pending_count in_progress_count total_count <<< "${counts}"
  pending_count="${pending_count:-0}"
  in_progress_count="${in_progress_count:-0}"

  if [[ "${pending_count}" == "0" && "${in_progress_count}" == "0" ]]; then
    decision="approve"
    reason="todo-enforcer: no pending todos"
    block_count=0
  elif (( block_count >= 10 )); then
    decision="approve"
    reason="todo-enforcer: safety valve after 10 consecutive blocks"
    block_count=0
  else
    decision="block"
    reason="todo-enforcer: pending todos (pending=${pending_count}, in_progress=${in_progress_count})"
    block_count=$((block_count + 1))
  fi
fi

mkdir -p "${STATE_DIR}"
printf '%s\n' "${block_count}" > "${STATE_FILE}"

python3 - <<'PY' "${decision}" "${reason}"
import json
import sys

decision = sys.argv[1]
reason = sys.argv[2]
print(json.dumps({"decision": decision, "reason": reason}))
PY
