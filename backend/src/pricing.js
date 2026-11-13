export const discountFor = (variant, category, brand) => (brand > 0 ? brand : category > 0 ? category : variant);

export const finalPrice = (mrp, discount) => ({
  mrp,
  discount,
  price: Math.round((mrp * (100 - discount)) / 100),
});
