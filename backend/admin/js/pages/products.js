import { h, toast, field, thumb, badge, confirmBox, guard, rupees } from '../ui.js';
import { api } from '../api.js';

export async function products(main) {
  let q = '';
  let page = 1;
  const body = h('div');
  const search = h('input', { type: 'search', placeholder: 'Search products', maxlength: 100 });
  const LIMIT = 20;

  async function load() {
    const { items, total } = await api('GET', '/products?q=' + encodeURIComponent(q) + '&page=' + page + '&limit=' + LIMIT);
    body.replaceChildren(
      h(
        'table',
        {},
        h('thead', {}, h('tr', {}, ['Image', 'Name', 'Category', 'Brand', 'Status', ''].map((t) => h('th', {}, t)))),
        h(
          'tbody',
          {},
          items.map((p) =>
            h(
              'tr',
              {},
              h('td', {}, p.image ? thumb(p.image, p.name) : '-'),
              h('td', {}, p.name),
              h('td', {}, p.category + ' / ' + p.subcategory),
              h('td', {}, p.brand ?? '-'),
              h('td', {}, p.status === 'draft' ? h('span', { class: 'badge' }, 'Draft') : badge(p.enabled, 'Live', 'Hidden')),
              h(
                'td',
                { class: 'row end' },
                h('a', { class: 'btn ghost sm', href: '#/products/' + p.id }, 'Edit'),
                h(
                  'button',
                  {
                    class: 'btn danger sm',
                    onclick: () =>
                      guard(async () => {
                        if (!(await confirmBox('Delete "' + p.name + '" permanently?'))) return;
                        await api('DELETE', '/products/' + p.id);
                        toast('Deleted');
                        await load();
                      }),
                  },
                  'Delete',
                ),
              ),
            ),
          ),
        ),
      ),
      h(
        'div',
        { class: 'row end' },
        h('span', { class: 'hint' }, total + ' products'),
        h('button', { class: 'btn ghost sm', disabled: page <= 1, onclick: () => { page--; guard(load); } }, 'Prev'),
        h('button', { class: 'btn ghost sm', disabled: page * LIMIT >= total, onclick: () => { page++; guard(load); } }, 'Next'),
      ),
    );
  }

  let timer;
  search.addEventListener('input', () => {
    clearTimeout(timer);
    timer = setTimeout(() => {
      q = search.value;
      page = 1;
      guard(load);
    }, 300);
  });

  main.replaceChildren(h('div', { class: 'head' }, h('h1', {}, 'Products'), h('div', { class: 'row' }, search, h('a', { class: 'btn', href: '#/products/new' }, 'Add product'))), body);
  await load();
}

const subOptions = (subs, selected) =>
  [...new Set(subs.map((s) => s.category_name))].map((c) =>
    h('optgroup', { label: c }, subs.filter((s) => s.category_name === c).map((s) => h('option', { value: s.id, selected: s.id === selected }, s.name))),
  );

const brandOptions = (brands, selected) => [h('option', { value: '' }, 'No brand'), ...brands.map((b) => h('option', { value: b.id, selected: b.id === selected }, b.name))];

export async function productNew(main) {
  const [subs, brands] = await Promise.all([api('GET', '/subcategories'), api('GET', '/brands')]);
  const name = h('input', { required: true, maxlength: 200 });
  const sub = h('select', { required: true }, subOptions(subs));
  const brand = h('select', {}, brandOptions(brands));
  const cat = h('output', {});
  const showCat = () => (cat.textContent = subs.find((s) => s.id === Number(sub.value))?.category_name ?? '-');
  sub.addEventListener('change', showCat);
  showCat();

  main.replaceChildren(
    h('div', { class: 'head' }, h('h1', {}, 'New product')),
    h(
      'form',
      {
        class: 'card',
        onsubmit: (e) => {
          e.preventDefault();
          guard(async () => {
            const { id } = await api('POST', '/products', { name: name.value, subcategory_id: Number(sub.value), brand_id: brand.value ? Number(brand.value) : null });
            location.hash = '#/products/' + id;
          });
        },
      },
      field('Product name', name),
      field('Subcategory', sub),
      h('div', { class: 'f' }, h('span', { class: 'hint' }, 'Category (automatic): '), cat),
      field('Brand (optional)', brand),
      h('button', { class: 'btn', type: 'submit' }, 'Save and continue'),
    ),
  );
}

export async function productEdit(main, id) {
  const [p, subs, brands] = await Promise.all([api('GET', '/products/' + id), api('GET', '/subcategories'), api('GET', '/brands')]);
  let specs = p.specifications.map((s) => ({ ...s }));
  let variants = p.variants.length ? p.variants.map((v) => ({ ...v })) : [{ name: 'Default', price: 0, discount: 0, is_default: true }];

  const name = h('input', { required: true, maxlength: 200, value: p.name });
  const sub = h('select', {}, subOptions(subs, p.subcategory_id));
  const brand = h('select', {}, brandOptions(brands, p.brand_id));
  const enabled = h('input', { type: 'checkbox', checked: p.enabled });
  const desc = h('textarea', { maxlength: 5000 }, p.description);
  const cat = h('output', {});
  const showCat = () => (cat.textContent = subs.find((s) => s.id === Number(sub.value))?.category_name ?? '-');
  sub.addEventListener('change', showCat);
  showCat();

  const specBox = h('div');
  const variantBox = h('div');
  const imgBox = h('div', { class: 'grid' });
  const status = h('span', {});
  const setStatus = (s) => status.replaceChildren(s === 'active' ? badge(true, 'Live', '') : h('span', { class: 'badge' }, 'Draft'));
  setStatus(p.status);

  function drawSpecs() {
    specBox.replaceChildren(
      ...specs.map((s, i) =>
        h(
          'div',
          { class: 'srow' },
          h('input', { placeholder: 'Name', maxlength: 80, value: s.key, 'aria-label': 'Specification name', oninput: (e) => (s.key = e.target.value) }),
          h('input', { placeholder: 'Value', maxlength: 500, value: s.value, 'aria-label': 'Specification value', oninput: (e) => (s.value = e.target.value) }),
          h('button', { class: 'btn ghost sm', type: 'button', onclick: () => { specs.splice(i, 1); drawSpecs(); } }, 'Remove'),
        ),
      ),
    );
  }

  function drawVariants() {
    variantBox.replaceChildren(
      ...variants.map((v, i) =>
        h(
          'div',
          { class: 'vrow' },
          h('input', { placeholder: 'Variant name', maxlength: 80, value: v.name, 'aria-label': 'Variant name', oninput: (e) => (v.name = e.target.value) }),
          h('input', { type: 'number', min: 0.01, step: '0.01', placeholder: 'Price', value: v.price ? rupees(v.price) : '', 'aria-label': 'Price in rupees', oninput: (e) => (v.price = Math.round(parseFloat(e.target.value) * 100)) }),
          h('input', { type: 'number', min: 0, max: 100, step: '0.01', placeholder: 'Discount %', value: v.discount, 'aria-label': 'Discount percent', oninput: (e) => (v.discount = parseFloat(e.target.value) || 0) }),
          h('label', { class: 'inline' }, h('input', { type: 'radio', name: 'default', checked: v.is_default, onchange: () => variants.forEach((x) => (x.is_default = x === v)) }), 'Default'),
          h('button', { class: 'btn ghost sm', type: 'button', disabled: variants.length === 1, onclick: () => { const was = v.is_default; variants.splice(i, 1); if (was) variants[0].is_default = true; drawVariants(); } }, 'Remove'),
        ),
      ),
    );
  }

  function drawImages(list) {
    imgBox.replaceChildren(
      ...list.map((im) =>
        h(
          'div',
          { class: 'tile' },
          h('img', { src: im.path, alt: p.name }),
          h('button', { class: 'btn danger sm', type: 'button', onclick: () => guard(async () => drawImages((await api('DELETE', '/products/' + id + '/images/' + im.id)).images)) }, 'Delete'),
        ),
      ),
    );
  }

  const files = h('input', {
    type: 'file',
    multiple: true,
    accept: 'image/jpeg,image/png,image/webp,image/gif,image/avif',
    onchange: () =>
      guard(async () => {
        const fd = new FormData();
        for (const f of files.files) fd.append('images', f);
        drawImages((await api('POST', '/products/' + id + '/images', fd)).images);
        files.value = '';
        toast('Images uploaded');
      }),
  });

  drawSpecs();
  drawVariants();
  drawImages(p.images);

  const save = () =>
    guard(async () => {
      if (variants.some((v) => !Number.isInteger(v.price) || v.price < 1)) throw new Error('Every variant needs a price');
      await api('PUT', '/products/' + id, {
        name: name.value,
        subcategory_id: Number(sub.value),
        brand_id: brand.value ? Number(brand.value) : null,
        enabled: enabled.checked,
        description: desc.value,
        specifications: specs.filter((s) => s.key.trim() || s.value.trim()),
        variants: variants.map(({ id, name, price, discount, is_default }) => ({ id, name, price, discount, is_default })),
      });
      setStatus('active');
      toast('Saved');
      const fresh = await api('GET', '/products/' + id);
      variants = fresh.variants;
      drawVariants();
    });

  main.replaceChildren(
    h('div', { class: 'head' }, h('h1', {}, 'Product details'), h('div', { class: 'row' }, status, h('a', { class: 'btn ghost', href: '#/products' }, 'Back'))),
    h(
      'div',
      { class: 'card' },
      field('Name', name),
      field('Subcategory', sub),
      h('div', { class: 'f' }, h('span', { class: 'hint' }, 'Category (automatic): '), cat),
      field('Brand', brand),
      h('label', { class: 'inline' }, enabled, 'Visible in the app'),
    ),
    h('div', { class: 'card' }, h('h2', {}, 'Description'), desc),
    h('div', { class: 'card' }, h('h2', {}, 'Specifications'), specBox, h('button', { class: 'btn ghost sm', type: 'button', onclick: () => { specs.push({ key: '', value: '' }); drawSpecs(); } }, 'Add specification')),
    h('div', { class: 'card' }, h('h2', {}, 'Images (at least one required)'), imgBox, field('Add images', files, 'Converted to WebP automatically.')),
    h(
      'div',
      { class: 'card' },
      h('h2', {}, 'Variants'),
      h('p', { class: 'hint' }, 'Exactly one default variant is shown on the home page, search and listings. Brand or category discounts override the variant discount.'),
      variantBox,
      h('button', { class: 'btn ghost sm', type: 'button', onclick: () => { variants.push({ name: '', price: 0, discount: 0, is_default: false }); drawVariants(); } }, 'Add variant'),
    ),
    h('button', { class: 'btn', type: 'button', onclick: save }, 'Save product'),
  );
}
