import { h, toast, icon } from './ui.js';
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
  ['#/orders', 'Orders', 'orders'],
  ['#/products', 'Products', 'products'],
  ['#/categories', 'Categories', 'categories'],
  ['#/subcategories', 'Subcategories', 'subcategories'],
  ['#/brands', 'Brands', 'brands'],
  ['#/mappings', 'Product mapping', 'mappings'],
  ['#/carousels', 'Carousels', 'carousels'],
  ['#/home', 'Home arrangement', 'home'],
];

const SIDE_KEY = 'wm_side_collapsed';
const readCollapsed = () => {
  try {
    return localStorage.getItem(SIDE_KEY) === '1';
  } catch {
    return false;
  }
};
const saveCollapsed = (v) => {
  try {
    localStorage.setItem(SIDE_KEY, v ? '1' : '0');
  } catch {}
};

function shell(hash, main) {
  const root = h('div', { class: 'shell' + (readCollapsed() ? ' collapsed' : '') });
  const toggle = h('button', { class: 'side-toggle', type: 'button', title: 'Toggle sidebar', 'aria-label': 'Toggle sidebar', 'aria-expanded': String(!root.classList.contains('collapsed')) }, icon('menu'));
  toggle.addEventListener('click', () => {
    const c = root.classList.toggle('collapsed');
    toggle.setAttribute('aria-expanded', String(!c));
    saveCollapsed(c);
  });
  root.append(
    h(
      'nav',
      { class: 'side', 'aria-label': 'Main' },
      h(
        'div',
        { class: 'side-top' },
        h('div', { class: 'brand' }, h('img', { class: 'logo-full', src: 'img/logo.png', alt: 'WeMatch' }), h('img', { class: 'logo-mark', src: 'img/mark.png', alt: 'WeMatch' })),
        toggle,
      ),
      links.map(([href, label, ic]) => h('a', { href, title: label, class: hash.startsWith(href) ? 'active' : '' }, icon(ic), h('span', { class: 'lbl' }, label))),
      h('div', { class: 'spacer' }),
      h(
        'button',
        {
          class: 'btn ghost signout',
          title: 'Sign out',
          onclick: async () => {
            await api('POST', '/auth/logout').catch(() => {});
            location.hash = '#/login';
          },
        },
        icon('logout'),
        h('span', { class: 'lbl' }, 'Sign out'),
      ),
    ),
    main,
  );
  return root;
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
