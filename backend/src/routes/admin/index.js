import { Router } from 'express';
import { csrfGuard, requireAdmin } from '../../auth.js';
import authRoutes from './auth.js';
import { taxonomy } from './taxonomy.js';
import products from './products.js';
import mappings from './mappings.js';
import carousels from './carousels.js';
import itemClasses from './itemClasses.js';
import orders from './orders.js';

const r = Router();

r.use(csrfGuard);
r.use('/auth', authRoutes);
r.use(requireAdmin);

r.use('/categories', taxonomy({ table: 'categories', discount: true, listSql: 'SELECT * FROM categories ORDER BY name' }));
r.use(
  '/subcategories',
  taxonomy({
    table: 'subcategories',
    parent: 'category_id',
    listSql: 'SELECT s.*, c.name AS category_name FROM subcategories s JOIN categories c ON c.id = s.category_id ORDER BY c.name, s.name',
  }),
);
r.use('/brands', taxonomy({ table: 'brands', discount: true, listSql: 'SELECT * FROM brands ORDER BY name' }));
r.use('/products', products);
r.use('/mappings', mappings);
r.use('/carousels', carousels);
r.use('/item-classes', itemClasses);
r.use('/orders', orders);

export default r;
