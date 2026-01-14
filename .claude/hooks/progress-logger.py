import json
import os
import sys
from datetime import datetime, timezone

TOOL_NAMES = {"Write", "Edit"}
TOOL_NAME_KEYS = ("tool_name", "toolName", "name", "tool")
TOOL_INPUT_KEYS = ("tool_input", "toolInput", "input")
FILE_PATH_KEYS = ("file_path", "filePath", "path", "filepath", "file")


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
    for key in TOOL_NAME_KEYS:
        value = payload.get(key)
        if isinstance(value, str):
            return value
    return ""


def extract_tool_input(payload):
    for key in TOOL_INPUT_KEYS:
        value = payload.get(key)
        if value is not None:
            return value
    return {}


def extract_file_path(tool_input):
    if isinstance(tool_input, dict):
        for key in FILE_PATH_KEYS:
            value = tool_input.get(key)
            if isinstance(value, str) and value:
                return value
            if isinstance(value, dict):
                nested = value.get("path")
                if isinstance(nested, str) and nested:
                    return nested
    elif isinstance(tool_input, str) and tool_input:
        return tool_input
    return ""


def resolve_log_path():
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    return os.path.join(base_dir, "progress.log")


def append_log(tool_name, file_path):
    timestamp = datetime.now(timezone.utc).isoformat()
    summary = file_path or "unknown file"
    line = f"[{timestamp}] {tool_name}: {summary}\n"
    log_path = resolve_log_path()
    os.makedirs(os.path.dirname(log_path), exist_ok=True)
    with open(log_path, "a", encoding="utf-8") as handle:
        handle.write(line)


def main():
    payload = read_payload()
    tool_name = extract_tool_name(payload)
    if tool_name not in TOOL_NAMES:
        return
    tool_input = extract_tool_input(payload)
    file_path = extract_file_path(tool_input)
    append_log(tool_name, file_path)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        sys.exit(0)
