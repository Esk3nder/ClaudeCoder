A behavioral specification for coding agents. Focus on **what** and **when**, not implementation details.                                                                                       
                                                                                                                                                                                                    
  ---                                                                                                                                                                                               
                                                                                                                                                                                                    
  ## Philosophy (Ralph Principles)                                                                                                                                                                  
                                                                                                                                                                                                    
  1. **Deterministic malicking**: Control what enters the context array. Less = better outcomes.                                                                                                    
  2. **The pin**: Specs are lookup tables that improve search tool hit rates. Don't invent—reference.                                                                                               
  3. **One goal per loop**: Fresh context per iteration. Compaction is lossy—avoid it.                                                                                                              
  4. **Low control, high oversight**: Let the agent decide, but watch and steer.                                                                                                                    
  5. **Completion signals**: Agent explicitly declares done. Quality gates verify it's true.                                                                                                        
                                                                                                                                                                                                    
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
  | todos | Config file | Block if pending/in_progress items |                                                                                                                                      
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
                                                                                                                                                                                                    
  **Location**: `.claude/guardrails.md`                                                                                                                                                             
                                                                                                                                                                                                    
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
                                                                                                                                                                                                    
  Inject into UserPromptSubmit `additionalContext`.                                                                                                                                                 
                                                                                                                                                                                                    
  ---                                                                                                                                                                                               
                                                                                                                                                                                                    
  ## Progress Log (Append-Only)                                                                                                                                                                     
                                                                                                                                                                                                    
  **Location**: `.claude/progress.log`                                                                                                                                                              
                                                                                                                                                                                                    
  **Format**:                                                                                                                                                                                       
  ```                                                                                                                                                                                               
  [ISO-timestamp] tool_name: summary                                                                                                                                                                
  ```                                                                                                                                                                                               
                                                                                                                                                                                                    
  Append on PostToolUse. Never overwrite.                                                                                                                                                           
                                                                                                                                                                                                    
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
                                                                                                                                                                                                    
  ## Agents (Minimal Set)                                                                                                                                                                           
                                                                                                                                                                                                    
  | Agent | When | Model |                                                                                                                                                                          
  |-------|------|-------|                                                                                                                                                                          
  | codebase-search | Find implementations | haiku |                                                                                                                                                
  | open-source-librarian | External docs/examples | sonnet |                                                                                                                                       
  | oracle | Architecture, repeated failures | opus |                                                                                                                                               
  | review | Code review (routes to specialists) | haiku |                                                                                                                                          
                                                                                                                                                                                                    
  **Pattern**: Fire search agents in background, continue work, collect when needed.                                                                                                                
                                                                                                                                                                                                    
  ---                                                                                                                                                                                               
                                                                                                                                                                                                    
  ## Failure Recovery                                                                                                                                                                               
                                                                                                                                                                                                    
  After 3 consecutive failures:                                                                                                                                                                     
  1. **Stop** editing                                                                                                                                                                               
  2. **Revert** to last working state                                                                                                                                                               
  3. **Document** what failed                                                                                                                                                                       
  4. **Escalate** to oracle or user                                                                                                                                                                 
                                                                                                                                                                                                    
  Never leave code broken.                                                                                                                                                                          
                                                                                                                                                                                                    
  ---                                                                                                                                                                                               
                                                                                                                                                                                                    
  ## State Files                                                                                                                                                                                    
                                                                                                                                                                                                    
  ```                                                                                                                                                                                               
  .claude/                                                                                                                                                                                          
  ├── hooks/state/session-context.json  # Session flags                                                                                                                                             
  ├── guardrails.md                     # Learned patterns                                                                                                                                          
  ├── progress.log                      # Append-only audit                                                                                                                                         
  └── .state/last_*.env                 # Gate caches                                                                                                                                               
                                                                                                                                                                                                    
  plans/                                                                                                                                                                                            
  ├── YYYYMMDD-{slug}.md                # Active plans                                                                                                                                              
  └── solutions/                        # Captured solutions                                                                                                                                        
  ```                                                                                                                                                                                               
                                                                                                                                                                                                    
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
                                                                                                                                                                                                    
  ## Hook Wiring (settings.json)                                                                                                                                                                    
                                                                                                                                                                                                    
  ```json                                                                                                                                                                                           
  {                                                                                                                                                                                                 
  "hooks": {                                                                                                                                                                                        
  "UserPromptSubmit": [                                                                                                                                                                             
  { "hooks": [{ "type": "command", "command": "~/.claude/hooks/keyword-detector.py" }] }                                                                                                            
  ],                                                                                                                                                                                                
  "PreToolUse": [                                                                                                                                                                                   
  { "matcher": "Read|Grep|Glob|Bash", "hooks": [{ "type": "command", "command": "~/.claude/hooks/parallel-dispatch-guide.py" }] }                                                                   
  ],                                                                                                                                                                                                
  "PostToolUse": [                                                                                                                                                                                  
  { "matcher": "Write|Edit", "hooks": [{ "type": "command", "command": "~/.claude/hooks/check-comments.py" }] }                                                                                     
  ],                                                                                                                                                                                                
  "Stop": [                                                                                                                                                                                         
  { "hooks": [{ "type": "command", "command": "~/.claude/hooks/workflows/require-green-tests.sh" }] },                                                                                              
  { "hooks": [{ "type": "command", "command": "~/.claude/hooks/workflows/require-clean-lint.sh" }] },                                                                                               
  { "hooks": [{ "type": "command", "command": "~/.claude/hooks/workflows/require-clean-types.sh" }] },                                                                                              
  { "hooks": [{ "type": "command", "command": "~/.claude/hooks/todo-enforcer.sh" }] }                                                                                                               
  ]                                                                                                                                                                                                 
  }                                                                                                                                                                                                 
  }                                                                                                                                                                                                 
  ```                                                                                                                                                                                               
                                                                                                                                                                                                    
  ---                                                                                                                                                                                               
                                                                                                                                                                                                    
  *Generated from synthesis of Ralph principles, Wreckit patterns, and CC-v3 enforcement models.*       
