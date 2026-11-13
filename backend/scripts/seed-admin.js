import bcrypt from 'bcryptjs';
import { randomBytes } from 'node:crypto';
import { db } from '../src/db.js';

const email = (process.env.ADMIN_EMAIL ?? '').trim().toLowerCase();
const generated = process.env.ADMIN_PASSWORD ? null : randomBytes(15).toString('base64url') + 'aA1';
const password = process.env.ADMIN_PASSWORD ?? generated;

if (!/^\S+@\S+\.\S+$/.test(email)) throw new Error('Set ADMIN_EMAIL');
if (password.length < 12 || password.length > 72 || !/[a-z]/.test(password) || !/[A-Z]/.test(password) || !/\d/.test(password)) {
  throw new Error('ADMIN_PASSWORD must be 12-72 chars with upper, lower and a digit');
}

await db
  .prepare(
    `INSERT INTO admins(email, password_hash) VALUES(?, ?)
     ON DUPLICATE KEY UPDATE password_hash = VALUES(password_hash), failed_attempts = 0, locked_until = 0`,
  )
  .run(email, await bcrypt.hash(password, 12));

console.log('Admin saved:', email);
if (generated) console.log('Generated password (shown once):', generated);
process.exit(0);
if (generated) console.log('Generated password (shown once):', generated);
