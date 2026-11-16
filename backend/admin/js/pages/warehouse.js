import { h, toast, field, guard } from '../ui.js';
import { api } from '../api.js';

export const mapLink = (lat, lng) => 'https://www.openstreetmap.org/?mlat=' + lat + '&mlon=' + lng + '#map=16/' + lat + '/' + lng;

export default async function warehouse(main) {
  const w = await api('GET', '/warehouse');
  const lat = h('input', { required: true, type: 'number', step: 'any', min: -90, max: 90, value: w.lat ?? '', placeholder: 'Latitude' });
  const lng = h('input', { required: true, type: 'number', step: 'any', min: -180, max: 180, value: w.lng ?? '', placeholder: 'Longitude' });
  const label = h('input', { maxlength: 120, value: w.label ?? '', placeholder: 'e.g. Kakkanad main warehouse' });
  const status = h('p', { class: 'hint' }, w.lat == null ? 'Warehouse location is not set. Orders will not get a delivery distance until it is.' : '');
  const view = h('a', { target: '_blank', rel: 'noopener noreferrer', class: 'btn ghost', hidden: w.lat == null, href: w.lat == null ? '#' : mapLink(w.lat, w.lng) }, 'View on map');

  const detect = h(
    'button',
    {
      class: 'btn ghost',
      type: 'button',
      onclick: () => {
        if (!navigator.geolocation) return toast('This browser does not support location', true);
        detect.disabled = true;
        navigator.geolocation.getCurrentPosition(
          (p) => {
            lat.value = p.coords.latitude.toFixed(7);
            lng.value = p.coords.longitude.toFixed(7);
            detect.disabled = false;
            toast('Location detected. Press Save to apply it.');
          },
          (err) => {
            detect.disabled = false;
            toast(err.code === 1 ? 'Location permission denied' : 'Could not detect location', true);
          },
          { enableHighAccuracy: true, timeout: 20000, maximumAge: 0 },
        );
      },
    },
    'Detect my current location',
  );

  main.replaceChildren(
    h('div', { class: 'head' }, h('h1', {}, 'Warehouse location')),
    h('p', { class: 'hint' }, 'Orders within 5 km of the warehouse are marked for in-house delivery; farther orders go to courier.'),
    h(
      'form',
      {
        class: 'card',
        onsubmit: (e) => {
          e.preventDefault();
          guard(async () => {
            const saved = await api('PUT', '/warehouse', { lat: Number(lat.value), lng: Number(lng.value), label: label.value });
            view.hidden = false;
            view.href = mapLink(saved.lat, saved.lng);
            status.textContent = '';
            toast('Warehouse location saved');
          });
        },
      },
      field('Label', label),
      h('div', { class: 'row' }, field('Latitude', lat), field('Longitude', lng)),
      status,
      h('div', { class: 'row end' }, detect, view, h('button', { class: 'btn', type: 'submit' }, 'Save')),
    ),
  );
}
