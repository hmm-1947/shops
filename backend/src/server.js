import express from 'express';
import helmet from 'helmet';
import cookieParser from 'cookie-parser';
import { rateLimit } from 'express-rate-limit';
import { config } from './config.js';
import './db.js';
import { errorHandler, notFound } from './errors.js';
import adminRoutes from './routes/admin/index.js';
import publicRoutes from './routes/public.js';
import orderRoutes from './routes/orders.js';

const app = express();
if (process.env.TRUST_PROXY) app.set('trust proxy', Number(process.env.TRUST_PROXY));

app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'"],
        styleSrc: ["'self'"],
        imgSrc: ["'self'", 'data:'],
        objectSrc: ["'none'"],
        frameAncestors: ["'none'"],
        upgradeInsecureRequests: config.prod ? [] : null,
      },
    },
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  }),
);
app.use(express.json({ limit: '100kb' }));
app.use(cookieParser());

app.use('/api', rateLimit({ windowMs: 60_000, limit: 300, standardHeaders: 'draft-7', legacyHeaders: false }));
app.use('/api/admin', adminRoutes);
app.use('/api/v1/orders', orderRoutes);
app.use('/api/v1', publicRoutes);
app.use('/api', notFound);

app.use('/uploads', express.static(config.uploadDir, { index: false, dotfiles: 'deny', maxAge: '365d', immutable: true }));
app.use('/admin', express.static(config.adminDir, { index: 'index.html' }));
app.get('/', (req, res) => res.redirect('/admin/'));

app.use(notFound);
app.use(errorHandler);

app.listen(config.port, () => console.log(`WeMatch backend on http://localhost:${config.port}  (admin: /admin/)`));
