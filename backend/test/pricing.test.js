import test from 'node:test';
import assert from 'node:assert/strict';
import { discountFor, finalPrice } from '../src/pricing.js';

test('brand beats category beats variant', () => {
  assert.equal(discountFor(10, 20, 30), 30);
  assert.equal(discountFor(10, 20, 0), 20);
  assert.equal(discountFor(10, 0, 0), 10);
});

test('final price in paise', () => {
  assert.deepEqual(finalPrice(149900, 20), { mrp: 149900, discount: 20, price: 119920 });
  assert.equal(finalPrice(999, 0).price, 999);
});
