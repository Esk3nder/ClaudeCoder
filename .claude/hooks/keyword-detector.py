import json
import os
import sys
from datetime import datetime, timezone

INTENT_KEYWORDS = {
    "review": ["review", "audit", "code review"],
    "plan": ["plan", "design", "architecture", "approach"],
    "debug": ["debug", "bug", "error", "fix", "issue", "broken"],
    "test": ["test", "verify", "validate"],
    "build": ["build", "compile", "package", "release"],
    "doc": ["doc", "docs", "documentation", "readme"],
}


def read_prompt_from_stdin():
    raw = sys.stdin.read()
    if not raw.strip():
        return "", False
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return "", True
    if not isinstance(data, dict):
        return "", True
    prompt = data.get("prompt", "")
    if not isinstance(prompt, str):
        prompt = ""
    return prompt, False


def detect_intent(prompt):
    lowered = prompt.lower()
    matched = []
    for intent, keywords in INTENT_KEYWORDS.items():
        if any(keyword in lowered for keyword in keywords):
            matched.append(intent)
    primary = matched[0] if matched else "general"
    flags = {f"is_{intent}": intent in matched for intent in INTENT_KEYWORDS}
    flags["is_general"] = not matched
    return primary, matched, flags


def read_guardrails_content():
    candidate_paths = [
        os.path.join(os.getcwd(), ".claude", "guardrails.md"),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "guardrails.md")),
    ]
    for path in candidate_paths:
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as handle:
                return handle.read()
    return ""


def write_session_context(context):
    state_path = os.path.expanduser("~/.claude/hooks/state/session-context.json")
    os.makedirs(os.path.dirname(state_path), exist_ok=True)
    temp_path = f"{state_path}.tmp"
    with open(temp_path, "w", encoding="utf-8") as handle:
        json.dump(context, handle, indent=2, sort_keys=True)
        handle.write("\n")
    os.replace(temp_path, state_path)


def main():
    prompt, parse_error = read_prompt_from_stdin()
    intent, matched_intents, flags = detect_intent(prompt)
    session_context = {
        "prompt": prompt,
        "detected_intent": intent,
        "intent_matches": matched_intents,
        "flags": flags,
        "parse_error": parse_error,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }
    write_session_context(session_context)

    guardrails_content = read_guardrails_content()
    hook_payload = {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": guardrails_content,
    }
    sys.stdout.write(json.dumps(hook_payload))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        sys.exit(0)
