export const schema = [
  `CREATE TABLE IF NOT EXISTS admins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(254) NOT NULL UNIQUE,
    password_hash VARCHAR(100) NOT NULL,
    failed_attempts INT NOT NULL DEFAULT 0,
    locked_until BIGINT NOT NULL DEFAULT 0
  )`,
  `CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(80) NOT NULL UNIQUE,
    image VARCHAR(255) NOT NULL,
    discount DECIMAL(5,2) NOT NULL DEFAULT 0,
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    CHECK (discount BETWEEN 0 AND 100)
  )`,
  `CREATE TABLE IF NOT EXISTS subcategories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    name VARCHAR(80) NOT NULL,
    image VARCHAR(255) NOT NULL,
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    UNIQUE KEY uq_sub_name (category_id, name),
    FOREIGN KEY (category_id) REFERENCES categories(id)
  )`,
  `CREATE TABLE IF NOT EXISTS brands (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(80) NOT NULL UNIQUE,
    image VARCHAR(255) NOT NULL,
    banner VARCHAR(255) NULL,
    discount DECIMAL(5,2) NOT NULL DEFAULT 0,
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    CHECK (discount BETWEEN 0 AND 100)
  )`,
  `CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    subcategory_id INT NOT NULL,
    brand_id INT NULL,
    description TEXT NOT NULL DEFAULT (''),
    specifications TEXT NOT NULL DEFAULT ('[]'),
    status ENUM('draft', 'active') NOT NULL DEFAULT 'draft',
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    created_at INT NOT NULL DEFAULT (UNIX_TIMESTAMP()),
    KEY idx_products_name (name),
    FOREIGN KEY (subcategory_id) REFERENCES subcategories(id),
    FOREIGN KEY (brand_id) REFERENCES brands(id)
  )`,
  `CREATE TABLE IF NOT EXISTS product_images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    path VARCHAR(255) NOT NULL,
    \`position\` INT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
  )`,
  `CREATE TABLE IF NOT EXISTS variants (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    name VARCHAR(80) NOT NULL,
    price INT NOT NULL,
    discount DECIMAL(5,2) NOT NULL DEFAULT 0,
    is_default TINYINT(1) NOT NULL DEFAULT 0,
    default_key INT GENERATED ALWAYS AS (IF(is_default = 1, product_id, NULL)) VIRTUAL,
    UNIQUE KEY one_default_variant (default_key),
    CHECK (price > 0),
    CHECK (discount BETWEEN 0 AND 100),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
  )`,
  `CREATE TABLE IF NOT EXISTS carousels (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(80) NOT NULL UNIQUE,
    enabled TINYINT(1) NOT NULL DEFAULT 1
  )`,
  `CREATE TABLE IF NOT EXISTS carousel_images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    carousel_id INT NOT NULL,
    image VARCHAR(255) NOT NULL,
    \`position\` INT NOT NULL,
    FOREIGN KEY (carousel_id) REFERENCES carousels(id) ON DELETE CASCADE
  )`,
  `CREATE TABLE IF NOT EXISTS item_classes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    display ENUM('scroll', 'list') NOT NULL,
    \`columns\` TINYINT NOT NULL DEFAULT 2,
    view_all_after INT NOT NULL DEFAULT 6,
    map_type ENUM('products', 'category', 'subcategory', 'brand', 'carousel') NOT NULL,
    map_id INT NULL,
    \`position\` INT NOT NULL,
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    CHECK (\`columns\` IN (2, 4)),
    CHECK (view_all_after >= 1)
  )`,
  `CREATE TABLE IF NOT EXISTS item_class_products (
    item_class_id INT NOT NULL,
    product_id INT NOT NULL,
    \`position\` INT NOT NULL,
    PRIMARY KEY (item_class_id, product_id),
    FOREIGN KEY (item_class_id) REFERENCES item_classes(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
  )`,
  `CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uid VARCHAR(128) NOT NULL,
    customer_name VARCHAR(120) NOT NULL DEFAULT '',
    customer_email VARCHAR(254) NOT NULL DEFAULT '',
    phone VARCHAR(20) NOT NULL DEFAULT '',
    city VARCHAR(60) NOT NULL DEFAULT '',
    address TEXT NOT NULL,
    payment_method ENUM('upi', 'card', 'net', 'wallet', 'cod') NOT NULL,
    subtotal BIGINT NOT NULL,
    delivery_fee INT NOT NULL,
    charges_total BIGINT NOT NULL DEFAULT 0,
    charges TEXT NOT NULL DEFAULT ('[]'),
    total BIGINT NOT NULL,
    latitude DECIMAL(10,7) NULL,
    longitude DECIMAL(10,7) NULL,
    distance_km DECIMAL(8,2) NULL,
    delivery_mode ENUM('in_house', 'courier') NULL,
    created_at INT NOT NULL DEFAULT (UNIX_TIMESTAMP()),
    KEY idx_orders_uid (uid),
    KEY idx_orders_status (status, created_at)
  )`,
  `CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    variant_id INT NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    brand VARCHAR(80) NULL,
    variant_name VARCHAR(80) NOT NULL,
    image VARCHAR(255) NULL,
    mrp INT NOT NULL,
    discount DECIMAL(5,2) NOT NULL,
    price INT NOT NULL,
    qty INT NOT NULL,
    CHECK (qty > 0),
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
  )`,
  `CREATE TABLE IF NOT EXISTS charges (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    type ENUM('fixed', 'percent') NOT NULL DEFAULT 'fixed',
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    CHECK (value >= 0)
  )`,
  `CREATE TABLE IF NOT EXISTS settings (
    k VARCHAR(60) PRIMARY KEY,
    v VARCHAR(255) NOT NULL
  )`,
];

export const columnMigrations = [
  ['orders', 'charges_total', 'BIGINT NOT NULL DEFAULT 0'],
  ['orders', 'charges', "TEXT NOT NULL DEFAULT ('[]')"],
  ['orders', 'latitude', 'DECIMAL(10,7) NULL'],
  ['orders', 'longitude', 'DECIMAL(10,7) NULL'],
  ['orders', 'distance_km', 'DECIMAL(8,2) NULL'],
  ['orders', 'delivery_mode', "ENUM('in_house', 'courier') NULL"],
  ['brands', 'banner', 'VARCHAR(255) NULL'],
];
