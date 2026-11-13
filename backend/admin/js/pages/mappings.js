import { h, toast, guard } from '../ui.js';
import { api } from '../api.js';

export default async function mappings(main, open) {
  const [m, subs, brands] = await Promise.all([api('GET', '/mappings'), api('GET', '/subcategories'), api('GET', '/brands')]);
  const detail = h('div');

  async function view(type, id, label) {
    const rows = await api('GET', '/mappings/products?type=' + type + '&id=' + id);
    detail.replaceChildren(
      h('h2', {}, 'Products in ' + label + ' (' + rows.length + ')'),
      rows.length
        ? h(
            'table',
            {},
            h('thead', {}, h('tr', {}, ['Product', 'Subcategory', 'Brand', ''].map((t) => h('th', {}, t)))),
            h(
              'tbody',
              {},
              rows.map((p) => {
                const sub = h('select', { 'aria-label': 'Subcategory' }, subs.map((s) => h('option', { value: s.id, selected: s.id === p.subcategory_id }, s.category_name + ' / ' + s.name)));
                const brand = h('select', { 'aria-label': 'Brand' }, [h('option', { value: '' }, 'No brand'), ...brands.map((b) => h('option', { value: b.id, selected: b.id === p.brand_id }, b.name))]);
                return h(
                  'tr',
                  {},
                  h('td', {}, h('a', { href: '#/products/' + p.id }, p.name)),
                  h('td', {}, sub),
                  h('td', {}, brand),
                  h(
                    'td',
                    {},
                    h(
                      'button',
                      {
                        class: 'btn sm',
                        onclick: () =>
                          guard(async () => {
                            await api('PATCH', '/mappings/products/' + p.id, { subcategory_id: Number(sub.value), brand_id: brand.value ? Number(brand.value) : null });
                            toast('Mapping updated');
                            await mappings(main, [type, id, label]);
                          }),
                      },
                      'Save',
                    ),
                  ),
                );
              }),
            ),
          )
        : h('p', { class: 'hint' }, 'No products mapped.'),
    );
    detail.scrollIntoView({ behavior: 'smooth' });
  }

  const block = (title, type, rows, name) =>
    h(
      'div',
      { class: 'card' },
      h('h2', {}, title),
      h(
        'table',
        {},
        h('tbody', {}, rows.map((r) => h('tr', {}, h('td', {}, name(r)), h('td', {}, r.count + ' products'), h('td', { class: 'row end' }, h('button', { class: 'btn ghost sm', onclick: () => guard(() => view(type, r.id, r.name)) }, 'View / manage'))))),
      ),
    );

  main.replaceChildren(
    h('div', { class: 'head' }, h('h1', {}, 'Product mapping')),
    block('Categories', 'category', m.categories, (r) => r.name),
    block('Subcategories', 'subcategory', m.subcategories, (r) => r.category + ' / ' + r.name),
    block('Brands', 'brand', m.brands, (r) => r.name),
    detail,
  );
  if (open) await view(...open);
}
