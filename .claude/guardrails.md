# Guardrails (Signs)

> Why: This file is injected on `UserPromptSubmit` so known safety checks and test expectations stay in context.

## Sign: Read Before Writing
- Trigger: Before modifying any file
- Instruction: Read the file first to avoid overwriting work
- Added: Initial template to support guardrail injection
