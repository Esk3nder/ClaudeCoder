import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

export async function install() {
  const __dirname = dirname(fileURLToPath(import.meta.url));
  const repoRoot = join(__dirname, '..', '..');
  const scriptPath = join(repoRoot, 'install.sh');

  return new Promise((resolve, reject) => {
    const child = spawn('bash', [scriptPath], {
      stdio: 'inherit',
      cwd: repoRoot
    });

    child.on('close', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`install.sh exited with code ${code}`));
      }
    });

    child.on('error', (err) => {
      reject(new Error(`Failed to run install.sh: ${err.message}`));
    });
  });
}
