import { Router } from 'express';
import { rateLimit } from 'express-rate-limit';
import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { db } from '../../db.js';
import { parse } from '../../errors.js';
import { COOKIE, cookieOptions, signToken, requireAdmin } from '../../auth.js';

const r = Router();
const dummyHash = bcrypt.hashSync('timing-equalizer', 12);
const MAX_FAILS = 5;
const LOCK_MS = 15 * 60 * 1000;

const limiter = rateLimit({ windowMs: LOCK_MS, limit: 20, standardHeaders: 'draft-7', legacyHeaders: false, message: { error: 'Too many attempts, try again later' } });

const loginSchema = z.object({
  email: z.string().trim().toLowerCase().email().max(254),
  password: z.string().min(1).max(72),
});

r.post('/login', limiter, async (req, res) => {
  const { email, password } = parse(loginSchema, req.body);
  const admin = db.prepare('SELECT * FROM admins WHERE email = ?').get(email);
  const now = Date.now();
  const ok = await bcrypt.compare(password, admin?.password_hash ?? dummyHash);

  if (admin && admin.locked_until > now) return res.status(429).json({ error: 'Too many attempts, try again later' });

  if (!admin || !ok) {
    if (admin) {
      const fails = admin.failed_attempts + 1;
      const locked = fails >= MAX_FAILS;
      db.prepare('UPDATE admins SET failed_attempts = ?, locked_until = ? WHERE id = ?').run(locked ? 0 : fails, locked ? now + LOCK_MS : 0, admin.id);
    }
    return res.status(401).json({ error: 'Invalid email or password' });
  }

  db.prepare('UPDATE admins SET failed_attempts = 0, locked_until = 0 WHERE id = ?').run(admin.id);
  res.cookie(COOKIE, signToken(admin.id), cookieOptions).json({ email: admin.email });
});

r.post('/logout', (req, res) => {
  res.clearCookie(COOKIE, { ...cookieOptions, maxAge: undefined }).json({ ok: true });
});

r.get('/me', requireAdmin, (req, res) => {
  const admin = db.prepare('SELECT email FROM admins WHERE id = ?').get(req.admin.sub);
  if (!admin) return res.status(401).json({ error: 'Unauthorized' });
  res.json(admin);
});

export default r;
