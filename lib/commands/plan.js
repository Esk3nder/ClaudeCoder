import { writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';

function slugify(text) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 50);
}

function formatDate() {
  const d = new Date();
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${year}${month}${day}`;
}

export async function plan(goal) {
  if (!goal) {
    console.error('Usage: coder plan "<goal>"');
    process.exit(1);
  }

  const plansDir = join(process.cwd(), 'plans');

  if (!existsSync(plansDir)) {
    mkdirSync(plansDir, { recursive: true });
  }

  const date = formatDate();
  const slug = slugify(goal);
  const filename = `${date}-${slug}.md`;
  const filepath = join(plansDir, filename);

  const content = `# Goal
${goal}

## Tasks
- [ ] Task 1
- [ ] Task 2

## Notes
- Why:
- Tests:
- Risks/Assumptions:
`;

  writeFileSync(filepath, content);
  console.log(`Created: ${filepath}`);
}
