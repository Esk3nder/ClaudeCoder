# Guardrails (Signs)

> Why: This file is injected on `UserPromptSubmit` so known safety checks and test expectations stay in context.

## Sign: Import Cycle
- Trigger: Adding or refactoring imports across modules
- Instruction: Check for circular dependencies before finalizing changes
- Added: Example guardrail to prevent runtime import loops

## Sign: Broken Tests
- Trigger: Changing behavior that affects existing tests
- Instruction: Run the relevant test suite and fix failures before committing
- Added: Example guardrail to keep tests green

## Sign: Unread Edits
- Trigger: Editing files without first reviewing the current contents
- Instruction: Read the file before modifying it to avoid overwriting work
- Added: Example guardrail to prevent accidental deletions
