#!/usr/bin/env node

import { parseArgs } from 'node:util';
import { install } from '../lib/commands/install.js';
import { plan } from '../lib/commands/plan.js';
import { build } from '../lib/commands/build.js';

const VERSION = '0.1.0';

const HELP = `
coder - Plan-driven execution wrapper for Claude Code

Usage:
  coder install              Install hooks to ~/.claude
  coder plan "<goal>"        Create a new plan file
  coder build <N>            Run N iterations on most recent plan

Options:
  --skip-tests               Skip test verification (sets WORKFLOWS_SKIP_TESTS)
  --no-commit                Skip git commit operations
  -h, --help                 Show this help
  -v, --version              Show version

Examples:
  coder install
  coder plan "Add user authentication"
  coder build 5
  coder build 1 --skip-tests
`.trim();

const { values, positionals } = parseArgs({
  options: {
    'skip-tests': { type: 'boolean', default: false },
    'no-commit': { type: 'boolean', default: false },
    help: { type: 'boolean', short: 'h', default: false },
    version: { type: 'boolean', short: 'v', default: false }
  },
  allowPositionals: true,
  strict: false
});

if (values['skip-tests']) {
  process.env.WORKFLOWS_SKIP_TESTS = 'true';
}
if (values['no-commit']) {
  process.env.WORKFLOWS_NO_COMMIT = 'true';
}

const [command, ...args] = positionals;

if (values.version) {
  console.log(VERSION);
  process.exit(0);
}

if (values.help || !command) {
  console.log(HELP);
  process.exit(0);
}

try {
  switch (command) {
    case 'install':
      await install();
      break;
    case 'plan':
      await plan(args[0]);
      break;
    case 'build':
      await build(parseInt(args[0], 10) || 1);
      break;
    default:
      console.error(`Unknown command: ${command}`);
      console.log(HELP);
      process.exit(1);
  }
} catch (err) {
  console.error(`Error: ${err.message}`);
  process.exit(1);
}
