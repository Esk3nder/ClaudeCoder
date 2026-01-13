# ClaudeCoder

A behavioral specification for coding agents. Focus on **what** and **when**, not implementation details.

---

## Philosophy (Ralph Principles)

1. **Deterministic malicking**: Control what enters the context array. Less = better outcomes.
2. **The pin**: Specs are lookup tables that improve search tool hit rates. Don't invent—reference.
3. **One goal per loop**: Fresh context per iteration. Compaction is lossy—avoid it.
4. **Low control, high oversight**: Let the agent decide, but watch and steer.
5. **Completion signals**: Agent explicitly declares done. Quality gates verify it's true.

---

## Quick Start

### Install with CLI (recommended)

```bash
git clone https://github.com/Esk3nder/ClaudeCoder.git
cd ClaudeCoder
npm link
coder install
```

### CLI Commands

```bash
# Install hooks to ~/.claude
coder install

# Create a new plan
coder plan "Add user authentication"

# Run 5 iterations on the most recent plan
coder build 5

# Run with skipped tests
coder build 3 --skip-tests

# Skip git operations
coder build 1 --no-commit

# Show help
coder --help
```

### Install (manual alternative)

```bash
git clone https://github.com/Esk3nder/ClaudeCoder.git
cd ClaudeCoder
./install.sh
```

Hooks install to `~/.claude/hooks/`, settings merge into `~/.claude/settings.json`.

### Restart Claude Code

The hooks activate on next session. No config needed.

### Test the hooks

```bash
# Intent detection (should return JSON with guardrails)
echo '{"prompt": "fix the auth bug"}' | python3 ~/.claude/hooks/keyword-detector.py

# Completion gate (should block - no transcript)
echo '{}' | bash ~/.claude/hooks/workflows/completion-signal.sh

# Check detected intent
cat ~/.claude/hooks/state/session-context.json
```

### Add a guardrail

When you hit a failure pattern, add it to `~/.claude/guardrails.md`:

```markdown
## Sign: Forgot to run tests
- Trigger: Completing a task without verification
- Instruction: Always run tests before claiming done
- Added: 2026-01-13
```

This gets injected into every prompt automatically.

### Create a plan (for non-trivial work)

```bash
cat > plans/$(date +%Y%m%d)-my-feature.md << 'EOF'
# Goal
Add user authentication to the API

## Tasks
- [ ] Create auth middleware
- [ ] Add login endpoint
- [ ] Add session management
- [ ] Write tests

## Notes
Using JWT tokens, 24h expiry
EOF
```

The agent reads the plan, marks tasks `[-]` in progress, executes, marks `[x]` done.

### Skip quality gates (if needed)

```bash
export WORKFLOWS_SKIP_TESTS=true
export WORKFLOWS_SKIP_LINT=true
export WORKFLOWS_SKIP_TYPES=true
```

### Uninstall

```bash
rm -rf ~/.claude/hooks ~/.claude/guardrails.md ~/.claude/progress.log
# Edit ~/.claude/settings.json to remove "hooks" key
```

---

## Lifecycle Hooks

| Event | When | Purpose |
|-------|------|---------|
| UserPromptSubmit | User message received | Inject context (mode hints, guardrails) |
| PreToolUse | Before tool executes | Advisory guidance or blocking |
| PostToolUse | After tool executes | Log progress, check quality |
| Stop | Completion attempted | Enforce quality gates |

**Hook output**: JSON with `additionalContext` (inject text) or `permissionDecision` (allow/deny).

---

## Stop Gates (Deterministic, In Order)

```
on Stop:
  tests → lint → types → todos → completion_signal
  any failure → block completion
```

| Gate | Skip Override | Behavior |
|------|---------------|----------|
| tests | `WORKFLOWS_SKIP_TESTS=true` | Auto-detect command, block on failure |
| lint | `WORKFLOWS_SKIP_LINT=true` | Auto-detect command, block on failure |
| types | `WORKFLOWS_SKIP_TYPES=true` | Auto-detect command, block on failure |
| todos | — | Block if pending/in_progress items |
| completion_signal | — | Require `<promise>COMPLETE</promise>` in output |

---

## Plan Files

**When**: Non-trivial work (2+ steps, multiple files, unclear scope).

**Location**: `plans/YYYYMMDD-{slug}.md`

**Format**:
```markdown
# Goal
One line success state

## Tasks
- [ ] Pending: action → verification
- [-] In progress
- [x] Done <!-- YYYY-MM-DD -->

## Notes
Decisions, blockers, findings
```

**Iteration loop** (non-negotiable):
1. Read plan (refresh goal in attention)
2. Mark task `[-]` in progress
3. Execute minimally
4. Mark task `[x]` with timestamp
5. Re-read plan before next task

---

## Guardrails (Learned Failure Modes)

**Location**: `~/.claude/guardrails.md`

**Format**:
```markdown
### Sign: [Pattern Name]
- **Trigger**: [When this applies]
- **Instruction**: [What to do]
- **Added**: [Date/incident reference]
```

**Example**:
```markdown
### Sign: Import Cycle
- **Trigger**: Adding imports between modules
- **Instruction**: Check circular dependencies first
- **Added**: 2026-01-10 module crash
```

Injected into UserPromptSubmit `additionalContext` on every prompt.

---

## Completion Signal

Agent must output `<promise>COMPLETE</promise>` before Stop gates allow completion.

**Verification**: Check transcript for signal. No signal = keep working.

---

## Classification (First Step)

| Type | Signal | Action |
|------|--------|--------|
| Trivial | Single file, obvious | Execute directly |
| Open-ended | "Add feature", "Refactor" | Create plan first |
| Ambiguous | Unclear scope | Ask ONE question |

**Default**: When uncertain → create plan.

---

## Failure Recovery

After 3 consecutive failures:
1. **Stop** editing
2. **Revert** to last working state
3. **Document** what failed
4. **Escalate** to oracle or user

Never leave code broken.

---

## Constraints (Hard Blocks)

| Never | Why |
|-------|-----|
| `as any`, `@ts-ignore` | Type safety |
| Commit without request | User controls git |
| Edit unread code | Understand first |
| Skip plan on non-trivial | No coordination |
| Claim done without signal | Quality unverified |

---

## What Gets Installed

```
~/.claude/
├── hooks/
│   ├── keyword-detector.py          # UserPromptSubmit: intent + guardrails
│   ├── parallel-dispatch-guide.py   # PreToolUse: advisory
│   ├── progress-logger.py           # PostToolUse: audit log
│   ├── state/session-context.json   # Session flags
│   └── workflows/
│       ├── require-green-tests.sh
│       ├── require-clean-lint.sh
│       ├── require-clean-types.sh
│       ├── todo-enforcer.sh
│       └── completion-signal.sh
├── guardrails.md                     # Learned patterns (editable)
├── settings.json                     # Hook wiring
└── progress.log                      # Append-only audit
```

