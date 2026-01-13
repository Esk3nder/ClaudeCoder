#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"
transcript_path="$(
  python3 -c '
import json
import sys

raw = sys.argv[1] if len(sys.argv) > 1 else ""
if not raw.strip():
    sys.exit(0)
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    sys.exit(0)

path = data.get("transcript_path") or data.get("transcriptPath") or ""
if isinstance(path, str):
    sys.stdout.write(path)
' "${payload}"
)"

decision="block"
reason="completion-signal: missing <promise>COMPLETE</promise>"

if [[ -z "${transcript_path}" || ! -f "${transcript_path}" ]]; then
  decision="block"
  reason="completion-signal: no transcript available"
else
  found="$(
    python3 - "${transcript_path}" <<'PY'
import json
import os
import sys

SIGNAL = "<promise>COMPLETE</promise>"
path = sys.argv[1]

def has_signal(text):
    return isinstance(text, str) and SIGNAL in text

def is_assistant(role):
    if not isinstance(role, str):
        return False
    role = role.lower()
    return role in ("assistant", "agent", "model")

def inspect_obj(obj, role_context=None):
    if isinstance(obj, dict):
        local_role = role_context
        for key in ("role", "type", "speaker", "author", "sender"):
            value = obj.get(key)
            if isinstance(value, str):
                local_role = value
                break
        if is_assistant(local_role):
            for value in obj.values():
                if isinstance(value, str) and has_signal(value):
                    return True
        for value in obj.values():
            if inspect_obj(value, local_role):
                return True
    elif isinstance(obj, list):
        for item in obj:
            if inspect_obj(item, role_context):
                return True
    elif isinstance(obj, str):
        if is_assistant(role_context) and has_signal(obj):
            return True
    return False

def parse_json_blob(text):
    try:
        data = json.loads(text)
    except Exception:
        return False
    return inspect_obj(data)

if not os.path.exists(path):
    print("no")
    sys.exit(0)

with open(path, "r", encoding="utf-8") as handle:
    content = handle.read()

found = parse_json_blob(content)
if not found:
    for line in content.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            data = json.loads(line)
        except Exception:
            continue
        if inspect_obj(data):
            found = True
            break

if not found and SIGNAL in content:
    found = True

print("yes" if found else "no")
PY
  )"
  if [[ "${found}" == "yes" ]]; then
    decision="allow"
    reason="completion-signal: found <promise>COMPLETE</promise>"
  else
    decision="block"
    reason="completion-signal: missing <promise>COMPLETE</promise>"
  fi
fi

python3 - <<'PY' "${decision}" "${reason}"
import json
import sys

decision = sys.argv[1]
reason = sys.argv[2]
print(json.dumps({"decision": decision, "reason": reason}))
PY
