// Copies shared assets from the mobile app (the single source of truth) into
// public/assets. Runs automatically before `dev` and `build`.
import { cpSync, mkdirSync, rmSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const src = join(here, '../../mobile/assets');
const out = join(here, '../public/assets');

if (!existsSync(src)) {
  console.error(`sync-assets: ${src} not found`);
  process.exit(1);
}
rmSync(out, { recursive: true, force: true });
mkdirSync(out, { recursive: true });
for (const dir of ['fonts', 'illustrations', 'sounds', 'branding']) {
  cpSync(join(src, dir), join(out, dir), { recursive: true });
}
console.log('sync-assets: copied fonts, illustrations, sounds, branding');
