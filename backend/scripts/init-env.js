import { writeFileSync } from 'node:fs';
import { randomBytes } from 'node:crypto';

try {
  writeFileSync(
    new URL('../.env', import.meta.url),
    `PORT=4000\nNODE_ENV=development\nJWT_SECRET=${randomBytes(48).toString('hex')}\n`,
    { flag: 'wx' },
  );
  console.log('.env created');
} catch (e) {
  if (e.code !== 'EEXIST') throw e;
  console.log('.env already exists');
}
