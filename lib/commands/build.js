import { spawn } from 'node:child_process';
import { readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';

function findMostRecentPlan(plansDir) {
  if (!existsSync(plansDir)) {
    return null;
  }

  const files = readdirSync(plansDir)
    .filter(f => f.endsWith('.md') && !f.toUpperCase().includes('TEMPLATE'))
    .sort()
    .reverse();

  return files[0] ? join(plansDir, files[0]) : null;
}

function buildPrompt(planPath) {
  return `Read the plan at ${planPath}.

Execute ONE iteration of the plan-driven loop:
1. Restate the goal in your own words
2. Find the next pending task (marked [ ]) and mark it [-] in progress
3. Execute the minimal change set for that task only
4. Verify the result with the appropriate checks/tests
5. Mark the task [x] done with a timestamp
6. Update Notes if decisions were made
7. Output <promise>COMPLETE</promise> when the iteration is done

Stop after completing ONE task. Do not continue to the next task.`;
}

async function runIteration(planPath) {
  const prompt = buildPrompt(planPath);

  return new Promise((resolve, reject) => {
    const child = spawn('claude', ['-p', prompt], {
      stdio: 'inherit',
      cwd: process.cwd()
    });

    child.on('close', (code) => {
      resolve(code);
    });

    child.on('error', (err) => {
      if (err.code === 'ENOENT') {
        reject(new Error('claude CLI not found. Install it with: npm install -g @anthropic-ai/claude-code'));
      } else {
        reject(err);
      }
    });
  });
}

export async function build(iterations) {
  const plansDir = join(process.cwd(), 'plans');
  const planPath = findMostRecentPlan(plansDir);

  if (!planPath) {
    console.error('No plan files found in ./plans/');
    console.error('Create one with: coder plan "your goal"');
    process.exit(1);
  }

  console.log(`Using plan: ${planPath}`);
  console.log(`Running ${iterations} iteration(s)...\n`);

  for (let i = 1; i <= iterations; i++) {
    console.log(`\n=== Iteration ${i}/${iterations} ===\n`);

    const code = await runIteration(planPath);

    if (code !== 0) {
      console.error(`\nIteration ${i} failed with exit code ${code}`);
      process.exit(code);
    }
  }

  console.log(`\n=== Completed ${iterations} iteration(s) ===`);
}
