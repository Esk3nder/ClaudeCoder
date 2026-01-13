# Goal
Working Claude Code configuration with lifecycle hooks, quality gates, plan-driven execution, guardrails injection, and completion signal enforcement.

## Constraints
- Files as memory (no database)
- Fail-safe hooks (exit 0 on errors)
- Deterministic gate ordering (tests → lint → types → todos → signal)
- One goal per loop (Ralph principles)

## Tasks

### Phase 1: Foundation
- [ ] S01: Create directory structure and settings.json.example
- [ ] S11: Create plan template and CLAUDE.md guidance

### Phase 2: Hooks
- [ ] S02: UserPromptSubmit hook (keyword-detector.py)
- [ ] S03: PreToolUse hook (parallel-dispatch-guide.py)
- [ ] S04: PostToolUse hook (progress-logger.py)

### Phase 3: Stop Gates
- [ ] S05: require-green-tests.sh
- [ ] S06: require-clean-lint.sh
- [ ] S07: require-clean-types.sh
- [ ] S08: todo-enforcer.sh
- [ ] S09: completion-signal.sh

### Phase 4: Guardrails
- [ ] S10: Guardrails template and injection

### Phase 5: Installation
- [ ] S12: Install script

## Verification
- [ ] All Python hooks pass `python3 -m py_compile`
- [ ] All Bash scripts pass `bash -n`
- [ ] settings.json.example is valid JSON
- [ ] install.sh runs without errors on clean system
- [ ] Stop gates block when conditions fail
- [ ] Completion signal is required

## Notes

### Architecture Decisions
- Python for UserPromptSubmit/PreToolUse/PostToolUse (JSON handling)
- Bash for Stop gates (simpler, faster for command detection)
- All hooks fail-safe (exit 0 on errors, never break the session)

### File Layout
```
.claude/
├── hooks/
│   ├── keyword-detector.py
│   ├── parallel-dispatch-guide.py
│   ├── progress-logger.py
│   ├── state/
│   │   └── session-context.json
│   └── workflows/
│       ├── require-green-tests.sh
│       ├── require-clean-lint.sh
│       ├── require-clean-types.sh
│       ├── todo-enforcer.sh
│       └── completion-signal.sh
├── guardrails.md
├── progress.log
└── .state/
    └── last_*.env

plans/
└── YYYYMMDD-{slug}.md
```

### Ralph Loop Integration
Each story executed as one iteration:
1. Read plan (goal in attention)
2. Mark task `[-]` in progress
3. Execute minimally
4. Verify acceptance criteria
5. Mark task `[x]` with timestamp
6. Output `<promise>COMPLETE</promise>`
