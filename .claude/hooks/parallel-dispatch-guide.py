import json
import os
import sys

TOOL_ADVICE = {
    "Read": "Prefer Grep/Glob to narrow scope before reading full files.",
    "Grep": "Use Grep for fast pattern search; pair with Glob to scope files.",
    "Glob": "Use Glob to enumerate files before selecting precise Reads.",
    "Bash": "Use Bash for quick inspections; keep commands focused and safe.",
}


def read_session_context():
    state_path = os.path.expanduser("~/.claude/hooks/state/session-context.json")
    if not os.path.exists(state_path):
        return {}
    with open(state_path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def read_payload():
    raw = sys.stdin.read()
    if not raw.strip():
        return {}
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError:
        return {}
    if not isinstance(payload, dict):
        return {}
    return payload


def extract_tool_name(payload):
    for key in ("tool_name", "toolName", "name", "tool"):
        value = payload.get(key)
        if isinstance(value, str):
            return value
    return ""


def build_reason(tool_name, session_context):
    advice = TOOL_ADVICE.get(tool_name, "Advisory guide for this tool is not defined.")
    intent = session_context.get("detected_intent", "general")
    flags = session_context.get("flags", {})
    if not isinstance(flags, dict):
        flags = {}
    active_flags = [name for name, enabled in flags.items() if enabled]
    if active_flags:
        flag_summary = ", ".join(sorted(active_flags))
        return f"{advice} Context intent: {intent}. Flags: {flag_summary}."
    return f"{advice} Context intent: {intent}."


def emit_allow(reason):
    payload = {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow",
        "permissionDecisionReason": reason,
    }
    sys.stdout.write(json.dumps(payload))


def main():
    payload = read_payload()
    tool_name = extract_tool_name(payload)
    session_context = read_session_context()
    reason = build_reason(tool_name, session_context)
    emit_allow(reason)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        emit_allow("Advisory guide unavailable; allowing tool use by default.")
        sys.exit(0)
