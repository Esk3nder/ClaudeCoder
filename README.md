# ClaudeCoder

Lifecycle hooks and quality gates for Claude Code. Enforces plan-driven execution, completion signals, and deterministic verification.

## Quick Start

```bash
# Clone the repo
git clone https://github.com/Esk3nder/ClaudeCoder.git
cd ClaudeCoder

# Install hooks to ~/.claude/
./install.sh
```

That's it. Restart Claude Code and the hooks are active.

## What Gets Installed

```
~/.claude/
├── hooks/
│   ├── keyword-detector.py      # Intent detection + guardrails injection
│   ├── parallel-dispatch-guide.py   # Tool use advisory
│   ├── progress-logger.py       # Logs Write/Edit to progress.log
│   ├── state/
│   │   └── session-context.json
│   └── workflows/
│       ├── require-green-tests.sh
│       ├── require-clean-lint.sh
│       ├── require-clean-types.sh
│       ├── todo-enforcer.sh
│       └── completion-signal.sh
├── guardrails.md                # Failure patterns (editable)
├── settings.json                # Hook wiring
└── progress.log                 # Tool usage log
```

## How It Works

### Lifecycle Hooks

| Event | Hook | Purpose |
|-------|------|---------|
| UserPromptSubmit | keyword-detector.py | Detects intent, injects guardrails |
| PreToolUse | parallel-dispatch-guide.py | Advisory for tool usage |
| PostToolUse | progress-logger.py | Logs file modifications |
| Stop | 5 workflow gates | Blocks completion until quality passes |

### Stop Gates (Run in Order)

```
tests → lint → types → todos → completion_signal
```

| Gate | What It Does | Skip With |
|------|--------------|-----------|
| require-green-tests.sh | Auto-runs detected test command | `WORKFLOWS_SKIP_TESTS=true` |
| require-clean-lint.sh | Auto-runs detected linter | `WORKFLOWS_SKIP_LINT=true` |
| require-clean-types.sh | Auto-runs type checker | `WORKFLOWS_SKIP_TYPES=true` |
| todo-enforcer.sh | Blocks if pending todos | - |
| completion-signal.sh | Requires `<promise>COMPLETE</promise>` | - |

### Completion Signal

The agent must output `<promise>COMPLETE</promise>` to finish a task. This ensures explicit declaration of completion rather than implicit stopping.

## Guardrails

Edit `~/.claude/guardrails.md` to add failure patterns you've encountered:

```markdown
## Sign: Import Cycle
- Trigger: Adding or refactoring imports across modules
- Instruction: Check for circular dependencies before finalizing changes
```

These get injected into context on every prompt, keeping learned lessons in attention.

## Plan-Driven Execution

For non-trivial work, create a plan file:

```
plans/YYYYMMDD-{slug}.md
```

See `plans/PLAN_TEMPLATE.md` for the format. The iteration loop:

1. Read plan, restate goal
2. Mark task in progress
3. Execute minimal change
4. Verify with tests/checks
5. Update plan with decisions
6. Mark complete + output `<promise>COMPLETE</promise>`

## Configuration

### Skip Quality Gates

```bash
export WORKFLOWS_SKIP_TESTS=true
export WORKFLOWS_SKIP_LINT=true
export WORKFLOWS_SKIP_TYPES=true
```

### Manual Hook Testing

```bash
# Test keyword detection
echo '{"prompt": "debug this auth bug"}' | python3 ~/.claude/hooks/keyword-detector.py

# Test completion signal (should block)
echo '{"transcript_path": "/tmp/test.json"}' | bash ~/.claude/hooks/workflows/completion-signal.sh
```

## Uninstall

```bash
rm -rf ~/.claude/hooks
rm ~/.claude/guardrails.md
# Edit ~/.claude/settings.json to remove hook entries
```

## Requirements

- Claude Code CLI
- Python 3.x
- Bash

## License

MIT

## See Also

- [SPEC.md](SPEC.md) - Full behavioral specification
- [CLAUDE.md](CLAUDE.md) - Agent instructions
