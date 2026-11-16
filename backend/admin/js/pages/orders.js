import { h, toast, modal, badge, guard, rupees } from '../ui.js';
import { api } from '../api.js';
import { mapLink } from './warehouse.js';

const STATUSES = [
  ['placed', 'Placed'],
  ['confirmed', 'Confirmed'],
  ['packed', 'Packed'],
  ['out_for_delivery', 'Out for delivery'],
  ['delivered', 'Delivered'],
  ['cancelled', 'Cancelled'],
];
const label = (s) => STATUSES.find(([v]) => v === s)?.[1] ?? s;
const when = (t) => new Date(t * 1000).toLocaleString();
const MODES = { in_house: 'In-house delivery', courier: 'Courier delivery' };
const mode = (m) => MODES[m] ?? 'Unknown';
const km = (d) => (d == null ? '-' : d + ' km');
const where = (o) => (o.latitude == null ? h('span', { class: 'hint' }, 'Not shared') : h('a', { href: mapLink(o.latitude, o.longitude), target: '_blank', rel: 'noopener noreferrer' }, Number(o.latitude).toFixed(5) + ', ' + Number(o.longitude).toFixed(5)));

export default async function orders(main) {
  const params = new URLSearchParams(location.hash.split('?')[1] ?? '');
  const status = params.get('status') ?? '';
  const page = Number(params.get('page')) || 1;
  const data = await api('GET', '/orders?page=' + page + (status ? '&status=' + status : ''));
  const go = (s, p) => (location.hash = '#/orders?' + new URLSearchParams({ ...(s ? { status: s } : {}), page: p }));

  async function view(id) {
    const o = await api('GET', '/orders/' + id);
    const select = h('select', {}, STATUSES.map(([v, l]) => h('option', { value: v, selected: v === o.status }, l)));
    const close = modal(
      'Order #' + o.id,
      h('p', {}, h('strong', {}, o.customer_name || 'Customer'), ' ', o.customer_email, o.phone ? ' / ' + o.phone : ''),
      h('p', { class: 'hint' }, when(o.created_at) + ' / ' + o.city + ' / ' + o.payment_method.toUpperCase()),
      h('p', {}, o.address.label + ': ' + o.address.lines.join(', ')),
      h(
        'table',
        {},
        h('thead', {}, h('tr', {}, ['Item', 'Variant', 'Qty', 'Price', 'Total'].map((t) => h('th', {}, t)))),
        h(
          'tbody',
          {},
          o.items.map((i) => h('tr', {}, h('td', {}, [i.brand, i.product_name].filter(Boolean).join(' ')), h('td', {}, i.variant_name), h('td', {}, i.qty), h('td', {}, rupees(i.price)), h('td', {}, rupees(i.price * i.qty)))),
        ),
      ),
      h('p', {}, h('strong', {}, 'Customer location: '), where(o)),
      h('p', {}, h('strong', {}, 'Distance from warehouse: '), km(o.distance_km), ' / ', mode(o.delivery_mode)),
      h(
        'p',
        {},
        'Subtotal ' + rupees(o.subtotal) + ' / Delivery ' + rupees(o.delivery_fee) + ' / ',
        o.charges.map((c) => c.name + ' ' + rupees(c.amount) + ' / '),
        h('strong', {}, 'Total ' + rupees(o.total)),
      ),

      h(
        'div',
        { class: 'row end' },
        select,
        h(
          'button',
          {
            class: 'btn',
            onclick: () =>
              guard(async () => {
                await api('PATCH', '/orders/' + o.id + '/status', { status: select.value });
                close();
                toast('Order updated');
                await orders(main);
              }),
          },
          'Update status',
        ),
      ),
    );
  }

  const pages = Math.max(1, Math.ceil(data.total / data.limit));
  main.replaceChildren(
    h('div', { class: 'head' }, h('h1', {}, 'Orders'), h('span', { class: 'hint' }, data.total + ' orders')),
    h(
      'div',
      { class: 'row' },
      h('button', { class: 'btn sm' + (status ? ' ghost' : ''), onclick: () => go('', 1) }, 'All'),
      STATUSES.map(([v, l]) => h('button', { class: 'btn sm' + (status === v ? '' : ' ghost'), onclick: () => go(v, 1) }, l + ' (' + (data.counts[v] ?? 0) + ')')),
    ),
    h(
      'table',
      {},
      h('thead', {}, h('tr', {}, ['#', 'Customer', 'City', 'Location', 'Distance', 'Delivery', 'Items', 'Total', 'Payment', 'Status', 'Placed', ''].map((t) => h('th', {}, t)))),
      h(
        'tbody',
        {},
        data.items.length
          ? data.items.map((o) =>
              h(
                'tr',
                {},
                h('td', {}, o.id),
                h('td', {}, o.customer_name || o.customer_email),
                h('td', {}, o.city),
                h('td', {}, where(o)),
                h('td', {}, km(o.distance_km)),
                h('td', {}, mode(o.delivery_mode)),
                h('td', {}, o.item_count),
                h('td', {}, rupees(o.total)),
                h('td', {}, o.payment_method.toUpperCase()),
                h('td', {}, badge(o.status === 'delivered', label(o.status), label(o.status))),
                h('td', {}, when(o.created_at)),
                h('td', {}, h('button', { class: 'btn ghost sm', onclick: () => guard(() => view(o.id)) }, 'View')),
              ),
            )
          : h('tr', {}, h('td', { colspan: 12 }, 'No orders yet')),
      ),
    ),
    h('div', { class: 'row end' }, h('button', { class: 'btn ghost sm', disabled: page <= 1, onclick: () => go(status, page - 1) }, 'Previous'), h('span', { class: 'hint' }, 'Page ' + page + ' of ' + pages), h('button', { class: 'btn ghost sm', disabled: page >= pages, onclick: () => go(status, page + 1) }, 'Next')),
  );
}
