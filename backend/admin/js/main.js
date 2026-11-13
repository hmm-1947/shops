import { h, toast } from './ui.js';
import { api } from './api.js';
import login from './pages/login.js';
import { products, productNew, productEdit } from './pages/products.js';
import { categories, subcategories, brands } from './pages/taxonomy.js';
import mappings from './pages/mappings.js';
import { carousels, carouselEdit } from './pages/carousels.js';
import homeLayout from './pages/home.js';
import orders from './pages/orders.js';

const routes = [
  [/^#\/products$/, products],
  [/^#\/products\/new$/, productNew],
  [/^#\/products\/(\d+)$/, productEdit],
  [/^#\/categories$/, categories],
  [/^#\/subcategories$/, subcategories],
  [/^#\/brands$/, brands],
  [/^#\/mappings$/, mappings],
  [/^#\/carousels$/, carousels],
  [/^#\/carousels\/(\d+)$/, carouselEdit],
  [/^#\/home$/, homeLayout],
  [/^#\/orders(\?.*)?$/, orders],
];

const links = [
  ['#/orders', 'Orders'],
  ['#/products', 'Products'],
  ['#/categories', 'Categories'],
  ['#/subcategories', 'Subcategories'],
  ['#/brands', 'Brands'],
  ['#/mappings', 'Product mapping'],
  ['#/carousels', 'Carousels'],
  ['#/home', 'Home arrangement'],
];

function shell(hash, main) {
  return h(
    'div',
    { class: 'shell' },
    h(
      'nav',
      { class: 'side', 'aria-label': 'Main' },
      h('div', { class: 'brand' }, 'WeMatch Admin'),
      links.map(([href, label]) => h('a', { href, class: hash.startsWith(href) ? 'active' : '' }, label)),
      h('div', { class: 'spacer' }),
      h(
        'button',
        {
          class: 'btn ghost',
          onclick: async () => {
            await api('POST', '/auth/logout').catch(() => {});
            location.hash = '#/login';
          },
        },
        'Sign out',
      ),
    ),
    main,
  );
}

async function render() {
  const hash = location.hash || '#/orders';
  document.querySelectorAll('.overlay').forEach((o) => o.remove());
  const app = document.getElementById('app');
  if (hash === '#/login') return login(app);
  try {
    await api('GET', '/auth/me');
  } catch {
    location.hash = '#/login';
    return;
  }
  const main = h('main', { class: 'main' });
  app.replaceChildren(shell(hash, main));
  for (const [re, page] of routes) {
    const m = re.exec(hash);
    if (m) {
      try {
        await page(main, ...m.slice(1));
      } catch (e) {
        toast(e.message, true);
      }
      return;
    }
  }
  main.append(h('p', {}, 'Page not found'));
}

addEventListener('hashchange', render);
render();
